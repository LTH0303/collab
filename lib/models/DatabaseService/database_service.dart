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

  // Update User Profile (Name, Phone, Location, Skills)
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  // --- SAVED JOBS MANAGEMENT (NEW) ---

  Future<void> toggleProjectSave(String userId, String projectId, bool shouldSave) async {
    final userRef = _db.collection('users').doc(userId);
    if (shouldSave) {
      await userRef.update({
        'saved_projects': FieldValue.arrayUnion([projectId])
      });
    } else {
      await userRef.update({
        'saved_projects': FieldValue.arrayRemove([projectId])
      });
    }
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
  void _removeDuplicateSubmissions(Milestone milestone) {
    Map<String, MilestoneSubmission> userSubmissions = {};

    for (var submission in milestone.submissions) {
      if (!userSubmissions.containsKey(submission.userId)) {
        userSubmissions[submission.userId] = submission;
      } else {
        MilestoneSubmission existing = userSubmissions[submission.userId]!;
        if (submission.submittedAt.isAfter(existing.submittedAt)) {
          userSubmissions[submission.userId] = submission;
        }
      }
    }
    milestone.submissions = userSubmissions.values.toList();
  }

  // --- HELPER: Check and Mark Expired Submissions ---
  // RESTORED: Logic to handle due dates
  Future<void> _checkAndMarkExpiredSubmissions(Milestone milestone, List<String> activeParticipants, String projectTitle) async {
    // 1. Check if due date exists and has passed
    if (milestone.submissionDueDate == null) return;
    if (!DateTime.now().isAfter(milestone.submissionDueDate!)) return;

    // 2. Check existing submissions for rejected status after deadline
    for (var submission in milestone.submissions) {
      if (submission.status == 'rejected') {
        submission.status = 'missed';
        submission.rejectionReason = "System: Rejected submission not re-uploaded before due date";
        // Apply penalty for failing to fix rejected work in time
        await _updateReliabilityScore(submission.userId, -20, "No Re-upload After Rejection", projectTitle: projectTitle);
      }
    }

    // 3. Check for No-Shows (Participants who never submitted)
    // Note: _penalizeNoShows usually handles this on phase completion,
    // but we can also trigger it here if the strict due date has passed.
    await _penalizeNoShows(milestone, activeParticipants, projectTitle);
  }

  // --- HELPER: Penalize No-Shows ---
  Future<void> _penalizeNoShows(Milestone milestone, List<String> activeParticipants, String projectTitle) async {
    Set<String> submittedUserIds = milestone.submissions.map((s) => s.userId).toSet();

    for (String participantId in activeParticipants) {
      if (!submittedUserIds.contains(participantId)) {
        // Check if we already marked them as missed to avoid double penalty
        int existingMissedIndex = milestone.submissions.indexWhere(
                (s) => s.userId == participantId && s.status == 'missed'
        );

        if (existingMissedIndex == -1) {
          // Apply Penalty
          await _updateReliabilityScore(participantId, -20, "No Show", projectTitle: projectTitle);

          // Add a "Missed" record so UI shows it
          milestone.submissions.add(MilestoneSubmission(
            userId: participantId,
            userName: "Participant (No Show)",
            expenseClaimed: "0",
            proofImageUrl: "",
            status: "missed",
            rejectionReason: "System: Phase ended or due date passed without submission",
            submittedAt: DateTime.now(),
          ));
        }
      }
    }
  }

  // --- PROJECT METHODS ---

  Future<void> addProject(Project project, String leaderId) async {
    project.status = 'active';
    project.createdAt = DateTime.now();
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

    if (currentPhaseIndex < milestones.length) {
      // Before unlocking next, finalize current phase penalties
      // This includes due date checks if they were set
      await _checkAndMarkExpiredSubmissions(milestones[currentPhaseIndex], activeParticipants, projectTitle);
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

      _removeDuplicateSubmissions(milestone);

      if (milestone.submissions.any((s) => s.status == 'pending')) {
        throw Exception("Cannot complete milestone: Some submissions are still pending.");
      }

      if (milestone.submissions.any((s) => s.status == 'rejected')) {
        throw Exception("Cannot complete milestone: Some submissions are rejected and need re-upload.");
      }

      // Final checks before closing phase
      await _checkAndMarkExpiredSubmissions(milestone, activeParticipants, projectTitle);
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

  Stream<List<Project>> getParticipantAllProjects(String userId) {
    return _db.collection('projects')
        .where('active_participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromJson(doc.data(), docId: doc.id))
        .toList());
  }

  Future<void> submitMilestone(String projectId, int milestoneIndex, String userId, String userName, String expense, String? photoUrl) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);
    final snapshot = await projectRef.get();
    if (!snapshot.exists) throw Exception("Project not found");

    final userDoc = await _db.collection('users').doc(userId).get();
    final actualName = userDoc.data()?['name'] ?? "Unknown Participant";

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<dynamic> rawMilestones = data['milestones'] ?? [];
    List<Milestone> milestones = rawMilestones.map((m) => Milestone.fromJson(m)).toList();

    if (milestoneIndex < milestones.length) {
      var milestone = milestones[milestoneIndex];

      // Check due date before allowing submission (Optional strict check)
      // if (milestone.submissionDueDate != null && DateTime.now().isAfter(milestone.submissionDueDate!)) {
      //   throw Exception("Submission failed: The due date for this milestone has passed.");
      // }

      int existingIndex = milestone.submissions.indexWhere((s) => s.userId == userId);

      final submission = MilestoneSubmission(
        userId: userId,
        userName: actualName,
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
      milestone.submissionDueDate = dueDate;

      // If extending due date, potentially reset 'missed' status if logical
      if (oldDueDate != null && DateTime.now().isBefore(dueDate)) {
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

  // Public method for ViewModel to trigger check manually if needed
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

      _removeDuplicateSubmissions(milestone);
      bool updated = false;

      // Logic block restored here as well for explicit calls
      if (milestone.submissionDueDate != null && DateTime.now().isAfter(milestone.submissionDueDate!)) {
        // 1. Penalize Rejects not fixed
        for (var submission in milestone.submissions) {
          if (submission.status == 'rejected') {
            submission.status = 'missed';
            submission.rejectionReason = "System: Rejected submission not re-uploaded before due date";
            await _updateReliabilityScore(submission.userId, -20, "No Re-upload After Rejection", projectTitle: projectTitle);
            updated = true;
          }
        }

        // 2. Penalize No Shows
        Set<String> submittedUserIds = milestone.submissions.map((s) => s.userId).toSet();
        for (String participantId in activeParticipants) {
          if (!submittedUserIds.contains(participantId)) {
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

      _removeDuplicateSubmissions(milestone);
      int subIndex = milestone.submissions.indexWhere((s) => s.userId == submissionUserId && s.status == 'pending');

      if (subIndex != -1) {
        milestone.submissions[subIndex].status = isApproved ? 'approved' : 'rejected';
        if (!isApproved) {
          milestone.submissions[subIndex].rejectionReason = rejectionReason;
        }

        await projectRef.update({
          'milestones': milestones.map((m) => m.toJson()).toList()
        });

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

      _removeDuplicateSubmissions(milestone);
      int subIndex = milestone.submissions.indexWhere((s) => s.userId == userId && s.status == 'pending');

      if (subIndex != -1) {
        milestone.submissions[subIndex].status = 'missed';
        milestone.submissions[subIndex].rejectionReason = 'Submission marked as missed';

        await projectRef.update({
          'milestones': milestones.map((m) => m.toJson()).toList()
        });

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

  Stream<List<Project>> streamLeaderAllProjects(String leaderId) {
    return _db
        .collection('projects')
        .where('leader_id', isEqualTo: leaderId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromJson(doc.data(), docId: doc.id))
        .toList());
  }

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