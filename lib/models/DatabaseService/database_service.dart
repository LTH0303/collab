// lib/models/DatabaseService/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'package:firebase_auth/firebase_auth.dart';
import '../ProjectRepository/project_model.dart';
import '../ProjectRepository/application_model.dart';
import '../CommunityRepository/post_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USER PROFILE MANAGEMENT ---

  // NEW: Update User Profile (Name, Phone, Location, Skills)
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  // --- SCORE MANAGEMENT ---

  Future<void> _updateReliabilityScore(String userId, int change, String reason, {String? projectTitle}) async {
    final userRef = _db.collection('users').doc(userId);

    try {
      final snapshot = await userRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data();
      int currentScore = (data?['reliability_score'] ?? 100) as int;

      int newScore = (currentScore + change).clamp(0, 100);

      // 1. Update Score Field
      await userRef.update({'reliability_score': newScore});

      // 2. Add History Record
      await userRef.collection('reliability_history').add({
        'change': change,
        'reason': reason,
        'project_title': projectTitle ?? 'General',
        'timestamp': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print("Error updating reliability score: $e");
    }
  }

  // --- HELPER: Remove Duplicate Submissions ---
  // Ensures only one submission per user exists (keeps the most recent one)
  void _removeDuplicateSubmissions(Milestone milestone) {
    Map<String, MilestoneSubmission> userSubmissions = {};

    // Collect submissions, keeping only the most recent one per user
    for (var submission in milestone.submissions) {
      if (!userSubmissions.containsKey(submission.userId)) {
        userSubmissions[submission.userId] = submission;
      } else {
        // If duplicate exists, keep the one with later submittedAt date
        MilestoneSubmission existing = userSubmissions[submission.userId]!;
        if (submission.submittedAt.isAfter(existing.submittedAt)) {
          userSubmissions[submission.userId] = submission;
        }
      }
    }

    // Replace submissions list with deduplicated version
    milestone.submissions = userSubmissions.values.toList();
  }

  // --- HELPER: Check and Mark Expired Submissions ---
  // Marks rejected submissions as "missed" if due date has passed
  Future<void> _checkAndMarkExpiredSubmissions(Milestone milestone, List<String> activeParticipants, String projectTitle) async {
    if (milestone.submissionDueDate == null) return;
    if (!DateTime.now().isAfter(milestone.submissionDueDate!)) return;

    // Find rejected submissions that passed due date
    for (var submission in milestone.submissions) {
      if (submission.status == 'rejected') {
        // Rejected submission passed due date → auto become Missing
        submission.status = 'missed';
        submission.rejectionReason = "System: Rejected submission not re-uploaded before due date";

        // Deduct reliability score for missing
        await _updateReliabilityScore(submission.userId, -20, "No Re-upload After Rejection", projectTitle: projectTitle);
      }
    }
  }

  // --- HELPER: Penalize No-Shows ---
  Future<void> _penalizeNoShows(Milestone milestone, List<String> activeParticipants, String projectTitle) async {
    Set<String> submittedUserIds = milestone.submissions.map((s) => s.userId).toSet();

    for (String participantId in activeParticipants) {
      if (!submittedUserIds.contains(participantId)) {
        // Check if user already has a "missed" submission (shouldn't happen, but safety check)
        int existingMissedIndex = milestone.submissions.indexWhere(
                (s) => s.userId == participantId && s.status == 'missed'
        );

        if (existingMissedIndex == -1) {
          // -20 for No Show
          await _updateReliabilityScore(participantId, -20, "No Show", projectTitle: projectTitle);

          milestone.submissions.add(MilestoneSubmission(
            userId: participantId,
            userName: "Participant (No Show)",
            expenseClaimed: "0",
            proofImageUrl: "",
            status: "missed",
            rejectionReason: "System: Phase ended without submission",
            submittedAt: DateTime.now(),
          ));
        }
        // If missed already exists, don't duplicate
      }
    }
  }

  // --- PROJECT METHODS ---

  Future<void> addProject(Project project, String leaderId) async {
    project.status = 'active';
    project.createdAt = DateTime.now(); // Set createdAt on project object
    for (var m in project.milestones) {
      m.status = 'locked';
    }
    await _db.collection('projects').add({
      ...project.toJson(),
      'leader_id': leaderId,
      'active_participants': [],
    });
  }

  Future<void> startProject(String projectId) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);
    final snapshot = await projectRef.get();
    if (!snapshot.exists) throw Exception("Project not found");

    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
    List<dynamic> milestonesRaw = data?['milestones'] ?? [];
    List<Milestone> milestones = milestonesRaw.map((m) => Milestone.fromJson(m)).toList();

    if (milestones.isNotEmpty) {
      milestones[0].status = 'open';
      await projectRef.update({
        'milestones': milestones.map((m) => m.toJson()).toList()
      });
    }
  }

  Future<void> unlockNextPhase(String projectId, int currentPhaseIndex) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);
    final snapshot = await projectRef.get();
    if (!snapshot.exists) throw Exception("Project not found");

    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
    String projectTitle = data?['project_title'] ?? "Project";
    List<dynamic> milestonesRaw = data?['milestones'] ?? [];
    List<String> activeParticipants = List<String>.from(data?['active_participants'] ?? []);

    List<Milestone> milestones = milestonesRaw.map((m) => Milestone.fromJson(m)).toList();

    // Check Penalties
    if (currentPhaseIndex < milestones.length) {
      await _penalizeNoShows(milestones[currentPhaseIndex], activeParticipants, projectTitle);
    }

    milestones[currentPhaseIndex].status = 'completed';
    int nextIndex = currentPhaseIndex + 1;
    if (nextIndex < milestones.length) {
      milestones[nextIndex].status = 'open';
    }

    await projectRef.update({
      'milestones': milestones.map((m) => m.toJson()).toList()
    });
  }

  Future<void> completeMilestone(String projectId, int milestoneIndex) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);
    final snapshot = await projectRef.get();
    if (!snapshot.exists) throw Exception("Project not found");

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    String projectTitle = data['project_title'] ?? "Project";
    List<dynamic> rawMilestones = data['milestones'] ?? [];
    List<String> activeParticipants = List<String>.from(data['active_participants'] ?? []);

    List<Milestone> milestones = rawMilestones.map((m) => Milestone.fromJson(m)).toList();

    if (milestoneIndex < milestones.length) {
      var milestone = milestones[milestoneIndex];

      // CRITICAL: Clean up any duplicate submissions (ensure only one per user)
      _removeDuplicateSubmissions(milestone);

      // Check for pending submissions
      if (milestone.submissions.any((s) => s.status == 'pending')) {
        throw Exception("Cannot complete milestone: Some submissions are still pending.");
      }

      // Check for rejected submissions (they need re-upload)
      if (milestone.submissions.any((s) => s.status == 'rejected')) {
        throw Exception("Cannot complete milestone: Some submissions are rejected and need re-upload.");
      }

      // Check and mark expired submissions (due date passed)
      await _checkAndMarkExpiredSubmissions(milestone, activeParticipants, projectTitle);

      // Check Penalties for participants without any submission
      await _penalizeNoShows(milestone, activeParticipants, projectTitle);

      milestone.status = 'completed';
      int nextIndex = milestoneIndex + 1;
      if (nextIndex < milestones.length) {
        milestones[nextIndex].status = 'open';
      }

      bool allCompleted = milestones.every((m) => m.status == 'completed');
      Map<String, dynamic> updateData = {
        'milestones': milestones.map((m) => m.toJson()).toList()
      };
      if (allCompleted) {
        updateData['status'] = 'completed';
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      await projectRef.update(updateData);
    }
  }

  // ... Queries ...
  Future<int> countLeaderActiveProjects(String leaderId) async {
    final snapshot = await _db.collection('projects')
        .where('leader_id', isEqualTo: leaderId)
        .where('status', isEqualTo: 'active')
        .get();
    return snapshot.docs.length;
  }

  Stream<List<Project>> getActiveProjects() {
    return _db.collection('projects')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromJson(doc.data(), docId: doc.id))
        .toList());
  }

  Stream<List<Project>> getLeaderProjects(String leaderId, String status) {
    return _db.collection('projects')
        .where('leader_id', isEqualTo: leaderId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromJson(doc.data(), docId: doc.id))
        .toList());
  }

  Future<bool> hasActiveJob(String participantId) async {
    final snapshot = await _db.collection('projects')
        .where('active_participants', arrayContains: participantId)
        .where('status', isEqualTo: 'active')
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Stream<List<Project>> getParticipantActiveProjects(String userId) {
    return _db.collection('projects')
        .where('active_participants', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromJson(doc.data(), docId: doc.id))
        .toList());
  }

  Future<void> submitMilestone(String projectId, int milestoneIndex, String userId, String userName, String expense, String? photoUrl) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);
    final snapshot = await projectRef.get();
    if (!snapshot.exists) throw Exception("Project not found");

    // --- NEW: FETCH ACTUAL NAME FROM FIRESTORE TO PREVENT EMPTY STRINGS ---
    final userDoc = await _db.collection('users').doc(userId).get();
    final actualName = userDoc.data()?['name'] ?? "Unknown Participant";
    // --------------------------------------------------------------------

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<dynamic> rawMilestones = data['milestones'] ?? [];
    List<Milestone> milestones = rawMilestones.map((m) => Milestone.fromJson(m)).toList();

    if (milestoneIndex < milestones.length) {
      var milestone = milestones[milestoneIndex];

      int existingIndex = milestone.submissions.indexWhere((s) => s.userId == userId);

      final submission = MilestoneSubmission(
        userId: userId,
        userName: actualName, // <--- USE THE FETCHED ACTUAL NAME
        expenseClaimed: expense,
        proofImageUrl: photoUrl ?? '',
        status: 'pending',
        submittedAt: DateTime.now(),
      );

      if (existingIndex != -1) {
        milestone.submissions[existingIndex] = submission;
      } else {
        milestone.submissions.add(submission);
      }

      await projectRef.update({
        'milestones': milestones.map((m) => m.toJson()).toList()
      });
    }
  }

  // Set or update submission due date for a milestone
  Future<void> setMilestoneDueDate(String projectId, int milestoneIndex, DateTime dueDate) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);
    final snapshot = await projectRef.get();
    if (!snapshot.exists) throw Exception("Project not found");

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<dynamic> rawMilestones = data['milestones'] ?? [];
    List<Milestone> milestones = rawMilestones.map((m) => Milestone.fromJson(m)).toList();

    if (milestoneIndex < milestones.length) {
      var milestone = milestones[milestoneIndex];
      DateTime? oldDueDate = milestone.submissionDueDate;

      // Update the due date
      milestone.submissionDueDate = dueDate;

      // If the new due date is in the future (hasn't passed yet) and there was an old due date,
      // remove "missed" submissions that were auto-created due to the old due date passing.
      // This handles both cases: extending a future due date, or resetting a past due date.
      if (oldDueDate != null && DateTime.now().isBefore(dueDate)) {
        // Remove "missed" submissions that were created because the old due date passed
        // These have the rejection reason "System: No submission before due date"
        milestone.submissions.removeWhere((submission) {
          return submission.status == 'missed' &&
              submission.rejectionReason == "System: No submission before due date";
        });
      }

      await projectRef.update({
        'milestones': milestones.map((m) => m.toJson()).toList()
      });
    }
  }

  // Check and auto-mark expired submissions (can be called periodically or when viewing milestone)
  Future<void> checkAndMarkExpiredSubmissions(String projectId, int milestoneIndex) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);
    final snapshot = await projectRef.get();
    if (!snapshot.exists) return;

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    String projectTitle = data['project_title'] ?? "Project";
    List<dynamic> rawMilestones = data['milestones'] ?? [];
    List<String> activeParticipants = List<String>.from(data['active_participants'] ?? []);
    List<Milestone> milestones = rawMilestones.map((m) => Milestone.fromJson(m)).toList();

    if (milestoneIndex < milestones.length) {
      var milestone = milestones[milestoneIndex];

      // CRITICAL: Clean up any duplicate submissions first
      _removeDuplicateSubmissions(milestone);

      bool updated = false;

      // Check if due date has passed
      if (milestone.submissionDueDate != null && DateTime.now().isAfter(milestone.submissionDueDate!)) {
        // Mark rejected submissions as missed
        for (var submission in milestone.submissions) {
          if (submission.status == 'rejected') {
            submission.status = 'missed';
            submission.rejectionReason = "System: Rejected submission not re-uploaded before due date";
            await _updateReliabilityScore(submission.userId, -20, "No Re-upload After Rejection", projectTitle: projectTitle);
            updated = true;
          }
        }

        // Mark participants without any submission as missed
        Set<String> submittedUserIds = milestone.submissions.map((s) => s.userId).toSet();
        for (String participantId in activeParticipants) {
          if (!submittedUserIds.contains(participantId)) {
            // Check if user already has a "missed" submission (prevent duplicates)
            int existingMissedIndex = milestone.submissions.indexWhere(
                    (s) => s.userId == participantId && s.status == 'missed'
            );

            if (existingMissedIndex == -1) {
              await _updateReliabilityScore(participantId, -20, "No Show", projectTitle: projectTitle);
              milestone.submissions.add(MilestoneSubmission(
                userId: participantId,
                userName: "Participant (No Show)",
                expenseClaimed: "0",
                proofImageUrl: "",
                status: "missed",
                rejectionReason: "System: No submission before due date",
                submittedAt: DateTime.now(),
              ));
              updated = true;
            }
            // If missed already exists, don't duplicate
          }
        }

        if (updated) {
          await projectRef.update({
            'milestones': milestones.map((m) => m.toJson()).toList()
          });
        }
      }
    }
  }

  Future<void> reviewMilestoneSubmission(String projectId, int milestoneIndex, String submissionUserId, bool isApproved, String? rejectionReason) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);

    final snapshot = await projectRef.get();
    if (!snapshot.exists) throw Exception("Project not found");

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    String projectTitle = data['project_title'] ?? "Project";
    List<dynamic> rawMilestones = data['milestones'] ?? [];
    List<Milestone> milestones = rawMilestones.map((m) => Milestone.fromJson(m)).toList();

    if (milestoneIndex < milestones.length) {
      var milestone = milestones[milestoneIndex];

      // CRITICAL: Clean up any duplicate submissions first
      _removeDuplicateSubmissions(milestone);

      // Find the user's submission (should only be one due to cleanup above)
      int subIndex = milestone.submissions.indexWhere((s) => s.userId == submissionUserId && s.status == 'pending');

      if (subIndex != -1) {
        milestone.submissions[subIndex].status = isApproved ? 'approved' : 'rejected';
        if (!isApproved) {
          milestone.submissions[subIndex].rejectionReason = rejectionReason;
        }

        await projectRef.update({
          'milestones': milestones.map((m) => m.toJson()).toList()
        });

        // Update Score
        if (isApproved) {
          await _updateReliabilityScore(submissionUserId, 10, "Verified Success", projectTitle: projectTitle);
        } else {
          await _updateReliabilityScore(submissionUserId, -5, "Rejection Penalty", projectTitle: projectTitle);
        }
      }
    }
  }

  Future<void> markSubmissionAsMissed(String projectId, int milestoneIndex, String userId) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);

    final snapshot = await projectRef.get();
    if (!snapshot.exists) throw Exception("Project not found");

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    String projectTitle = data['project_title'] ?? "Project";
    List<dynamic> rawMilestones = data['milestones'] ?? [];
    List<Milestone> milestones = rawMilestones.map((m) => Milestone.fromJson(m)).toList();

    if (milestoneIndex < milestones.length) {
      var milestone = milestones[milestoneIndex];

      // CRITICAL: Clean up any duplicate submissions first
      _removeDuplicateSubmissions(milestone);

      // Find the user's submission (should only be one due to cleanup above)
      int subIndex = milestone.submissions.indexWhere((s) => s.userId == userId && s.status == 'pending');

      if (subIndex != -1) {
        milestone.submissions[subIndex].status = 'missed';
        milestone.submissions[subIndex].rejectionReason = 'Submission marked as missed';

        await projectRef.update({
          'milestones': milestones.map((m) => m.toJson()).toList()
        });

        // Update Score
        await _updateReliabilityScore(userId, -20, "No Show", projectTitle: projectTitle);
      }
    }
  }

  Future<void> addApplication(Application app) async {
    await _db.collection('applications').add(app.toJson());
  }

  Future<int> countUserPendingApplications(String userId) async {
    final snapshot = await _db.collection('applications')
        .where('applicant_id', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }

  Future<bool> hasAppliedToProject(String userId, String projectId) async {
    final snapshot = await _db.collection('applications')
        .where('applicant_id', isEqualTo: userId)
        .where('project_id', isEqualTo: projectId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<String?> getApplicationStatus(String userId, String projectId) async {
    final snapshot = await _db.collection('applications')
        .where('applicant_id', isEqualTo: userId)
        .where('project_id', isEqualTo: projectId)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data()['status'] as String?;
    }
    return null;
  }

  Stream<List<Application>> getLeaderPendingApplications(String leaderId) {
    return _db.collection('applications')
        .where('leader_id', isEqualTo: leaderId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Application.fromJson(doc.data(), docId: doc.id))
        .toList());
  }

  Stream<List<Application>> getProjectPendingApplications(String projectId) {
    return _db.collection('applications')
        .where('project_id', isEqualTo: projectId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Application.fromJson(doc.data(), docId: doc.id))
        .toList());
  }

  Stream<List<Application>> getProjectApprovedApplications(String projectId) {
    return _db.collection('applications')
        .where('project_id', isEqualTo: projectId)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Application.fromJson(doc.data(), docId: doc.id))
        .toList());
  }

  Future<void> updateApplicationStatus(String appId, String status) async {
    await _db.collection('applications').doc(appId).update({'status': status});
  }

  Future<void> approveApplicationTransaction(Application app) async {
    WriteBatch batch = _db.batch();
    DocumentReference appRef = _db.collection('applications').doc(app.id);
    DocumentReference projectRef = _db.collection('projects').doc(app.projectId);

    QuerySnapshot otherAppsSnapshot = await _db.collection('applications')
        .where('applicant_id', isEqualTo: app.applicantId)
        .where('status', isEqualTo: 'pending')
        .get();

    batch.update(appRef, {'status': 'approved'});
    batch.update(projectRef, {
      'active_participants': FieldValue.arrayUnion([app.applicantId])
    });

    for (var doc in otherAppsSnapshot.docs) {
      if (doc.id != app.id) {
        batch.update(doc.reference, {'status': 'withdrawn'});
      }
    }
    await batch.commit();
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }

  Stream<Map<String, dynamic>?> streamUserProfile(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      return doc.exists ? doc.data() : null;
    });
  }

  Future<Project?> getProjectById(String projectId) async {
    try {
      final doc = await _db.collection('projects').doc(projectId).get();
      return doc.exists ? Project.fromJson(doc.data()!, docId: doc.id) : null;
    } catch (e) {
      return null;
    }
  }

  Stream<Project?> streamProject(String projectId) {
    return _db.collection('projects').doc(projectId).snapshots().map((doc) {
      if (doc.exists) {
        return Project.fromJson(doc.data()!, docId: doc.id);
      }
      return null;
    });
  }

  Future<void> finalizeProject(String projectId) async {
    await _db.collection('projects').doc(projectId).update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  // Stream all projects for a leader (any status)
  Stream<List<Project>> streamLeaderAllProjects(String leaderId) {
    return _db
        .collection('projects')
        .where('leader_id', isEqualTo: leaderId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromJson(doc.data(), docId: doc.id))
        .toList());
  }

  // --- IMPACT / POPULATION HELPERS ---
  Future<void> updateProjectPopulation(String projectId, {int? initialPopulation, int? currentPopulation}) async {
    final Map<String, dynamic> data = {};
    if (initialPopulation != null) {
      data['initial_population'] = initialPopulation;
    }
    if (currentPopulation != null) {
      data['current_population'] = currentPopulation;
    }
    if (data.isEmpty) return;
    await _db.collection('projects').doc(projectId).update(data);
  }

  Stream<List<PostModel>> getPostsStream(String currentUserId) {
    return _db.collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PostFactory.createPost(doc.id, doc.data(), currentUserId))
        .toList());
  }

  Future<void> createPost(PostModel post) async {
    await _db.collection('posts').add(post.toJson());
  }

  Future<void> togglePostLike(String postId, String userId, bool shouldLike) async {
    final ref = _db.collection('posts').doc(postId);
    if (shouldLike) {
      await ref.update({'likedBy': FieldValue.arrayUnion([userId])});
    } else {
      await ref.update({'likedBy': FieldValue.arrayRemove([userId])});
    }
  }

  Future<void> addPostComment(String postId, String comment) async {
    await _db.collection('posts').doc(postId).update({
      'comments': FieldValue.arrayUnion([comment])
    });
  }
}