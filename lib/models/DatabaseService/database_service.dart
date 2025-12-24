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

  // --- HELPER: Fetch User Name from Firestore ---
  Future<String> _fetchUserName(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final name = userDoc.data()?['name'] as String?;
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    } catch (e) {
      print("Error fetching user name for $userId: $e");
    }
    return "Unknown Participant";
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
  Future<void> _checkAndMarkExpiredSubmissions(Milestone milestone, List<String> activeParticipants, String projectTitle) async {
    if (milestone.submissionDueDate == null) return;
    if (!DateTime.now().isAfter(milestone.submissionDueDate!)) return;

    // Mark rejected submissions as missed
    for (var submission in milestone.submissions) {
      if (submission.status == 'rejected') {
        submission.status = 'missed';
        submission.rejectionReason = "System: Rejected submission not re-uploaded before due date";
        // Update name if it's still unknown or empty
        if (submission.userName == "Unknown Participant" || submission.userName.isEmpty || submission.userName == "Unknown") {
          submission.userName = await _fetchUserName(submission.userId);
        }
        await _updateReliabilityScore(submission.userId, -20, "No Re-upload After Rejection", projectTitle: projectTitle);
      }
    }

    // Mark participants without submissions as missed
    Set<String> submittedUserIds = milestone.submissions.map((s) => s.userId).toSet();
    for (String participantId in activeParticipants) {
      if (!submittedUserIds.contains(participantId)) {
        int existingMissedIndex = milestone.submissions.indexWhere(
                (s) => s.userId == participantId && s.status == 'missed'
        );

        if (existingMissedIndex == -1) {
          final userName = await _fetchUserName(participantId);
          await _updateReliabilityScore(participantId, -20, "No Show", projectTitle: projectTitle);
          milestone.submissions.add(MilestoneSubmission(
            userId: participantId,
            userName: userName,
            expenseClaimed: "0",
            proofImageUrl: "",
            status: "missed",
            rejectionReason: "System: No submission before due date",
            submittedAt: DateTime.now(),
          ));
        }
      }
    }
  }

  // --- HELPER: Penalize No-Shows ---
  Future<void> _penalizeNoShows(Milestone milestone, List<String> activeParticipants, String projectTitle) async {
    Set<String> submittedUserIds = milestone.submissions.map((s) => s.userId).toSet();

    for (String participantId in activeParticipants) {
      if (!submittedUserIds.contains(participantId)) {
        int existingMissedIndex = milestone.submissions.indexWhere(
                (s) => s.userId == participantId && s.status == 'missed'
        );

        if (existingMissedIndex == -1) {
          final userName = await _fetchUserName(participantId);
          await _updateReliabilityScore(participantId, -20, "No Show", projectTitle: projectTitle);

          milestone.submissions.add(MilestoneSubmission(
            userId: participantId,
            userName: userName,
            expenseClaimed: "0",
            proofImageUrl: "",
            status: "missed",
            rejectionReason: "System: Phase ended without submission",
            submittedAt: DateTime.now(),
          ));
        }
      }
    }
  }

  // --- PROJECT METHODS ---

  Future<void> addProject(Project project, String leaderId) async {
    // UPDATED: Respect the status passed in the project object (default 'draft' if empty)
    if (project.status.isEmpty) {
      project.status = 'draft';
    }

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

  // NEW: Publish a draft project (update status to 'active')
  Future<void> publishProjectFromDraft(String projectId) async {
    await _db.collection('projects').doc(projectId).update({
      'status': 'active',
      // We keep original created_at or update it? Keeping original created_at is safer for sorting.
    });
  }

  // NEW: Update generic project details (for Edit Page)
  Future<void> updateProjectDetails(String projectId, Map<String, dynamic> data) async {
    await _db.collection('projects').doc(projectId).update(data);
  }

  // NEW: Delete a project (for removing drafts)
  Future<void> deleteProject(String projectId) async {
    await _db.collection('projects').doc(projectId).delete();
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

  // FIXED: unlockNextPhase logic to allow MISSED submissions
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
      var milestone = milestones[currentPhaseIndex];

      // 1. Filter latest submissions
      _removeDuplicateSubmissions(milestone);

      // 2. BLOCK if there are pending submissions
      if (milestone.submissions.any((s) => s.status == 'pending')) {
        throw Exception("Cannot unlock next phase: Some submissions are still pending review.");
      }

      // 3. BLOCK if there are rejected submissions
      if (milestone.submissions.any((s) => s.status == 'rejected')) {
        throw Exception("Cannot unlock next phase: Rejected submissions must be resolved (re-uploaded or expired).");
      }

      // Note: 'missed' and 'approved' are allowed to proceed.

      // 4. Handle penalties for no-shows before closing
      await _penalizeNoShows(milestone, activeParticipants, projectTitle);
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

      // Check and mark expired submissions first (if due date has passed)
      await _checkAndMarkExpiredSubmissions(milestone, activeParticipants, projectTitle);

      // Validate: All participants must have a submission (approved or missed)
      Set<String> submittedUserIds = milestone.submissions.map((s) => s.userId).toSet();
      for (String participantId in activeParticipants) {
        if (!submittedUserIds.contains(participantId)) {
          throw Exception("Cannot complete milestone: Not all participants have submitted. Missing submission from participant.");
        }
      }

      // Validate: No pending submissions
      if (milestone.submissions.any((s) => s.status == 'pending')) {
        throw Exception("Cannot complete milestone: Some submissions are still pending review.");
      }

      // Validate: No rejected submissions
      if (milestone.submissions.any((s) => s.status == 'rejected')) {
        throw Exception("Cannot complete milestone: Some submissions are rejected and need re-upload.");
      }

      // All submissions must be either approved or missed
      bool allValid = milestone.submissions.every((s) => s.status == 'approved' || s.status == 'missed');
      if (!allValid) {
        throw Exception("Cannot complete milestone: Some submissions are in an invalid state.");
      }

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

  // --- NEW: Retrieve Application Object for ID ---
  Future<Application?> getUserApplicationForProject(String userId, String projectId) async {
    final snapshot = await _db.collection('applications')
        .where('applicant_id', isEqualTo: userId)
        .where('project_id', isEqualTo: projectId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return Application.fromJson(snapshot.docs.first.data(), docId: snapshot.docs.first.id);
    }
    return null;
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

    // Always fetch the latest name from Firestore to ensure accuracy
    final actualName = await _fetchUserName(userId);

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<dynamic> rawMilestones = data['milestones'] ?? [];
    List<Milestone> milestones = rawMilestones.map((m) => Milestone.fromJson(m)).toList();

    if (milestoneIndex < milestones.length) {
      var milestone = milestones[milestoneIndex];
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

      // FIX: Compare both in UTC to avoid timezone issues
      final nowUtc = DateTime.now().toUtc();
      final newDueDateUtc = dueDate.toUtc();
      if (oldDueDate != null && nowUtc.isBefore(newDueDateUtc)) {
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

  Future<void> checkAndMarkExpiredSubmissions(String projectId, int milestoneIndex) async {
    print("🔍 checkAndMarkExpiredSubmissions called for project $projectId, milestone $milestoneIndex");
    DocumentReference projectRef = _db.collection('projects').doc(projectId);
    final snapshot = await projectRef.get();
    if (!snapshot.exists) {
      print("❌ Project not found: $projectId");
      return;
    }

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    String projectTitle = data['project_title'] ?? "Project";
    List<dynamic> rawMilestones = data['milestones'] ?? [];
    List<String> activeParticipants = List<String>.from(data['active_participants'] ?? []);
    List<Milestone> milestones = rawMilestones.map((m) => Milestone.fromJson(m)).toList();

    print("📊 Active participants: ${activeParticipants.length} - ${activeParticipants.join(', ')}");

    if (milestoneIndex < milestones.length) {
      var milestone = milestones[milestoneIndex];

      _removeDuplicateSubmissions(milestone);
      bool updated = false;

      print("📅 Milestone due date: ${milestone.submissionDueDate} (UTC: ${milestone.submissionDueDate?.toUtc()})");
      print("⏰ Current time: ${DateTime.now()} (UTC: ${DateTime.now().toUtc()})");
      print("📝 Current submissions: ${milestone.submissions.length}");
      for (var sub in milestone.submissions) {
        print("   - ${sub.userId}: ${sub.status}");
      }

      // FIX: Compare both in UTC to avoid timezone issues
      // The due date from Firestore is stored as UTC (via toIso8601String())
      // DateTime.now() is local time, so we convert both to UTC for accurate comparison
      final nowUtc = DateTime.now().toUtc();
      final dueDateUtc = milestone.submissionDueDate?.toUtc();

      if (milestone.submissionDueDate != null && dueDateUtc != null && nowUtc.isAfter(dueDateUtc)) {
        print("✅ Due date HAS PASSED - checking for missing submissions");

        // First, refresh names for any existing submissions with unknown/empty names
        for (var submission in milestone.submissions) {
          if (submission.userName == "Unknown Participant" ||
              submission.userName.isEmpty ||
              submission.userName == "Unknown" ||
              submission.userName == "Participant (No Show)") {
            submission.userName = await _fetchUserName(submission.userId);
            updated = true;
            print("   🔄 Refreshed name for ${submission.userId}: ${submission.userName}");
          }
        }

        // Mark rejected submissions as missed
        for (var submission in milestone.submissions) {
          if (submission.status == 'rejected') {
            print("   🔄 Marking rejected submission as missed: ${submission.userId}");
            submission.status = 'missed';
            submission.rejectionReason = "System: Rejected submission not re-uploaded before due date";
            // Ensure name is correct
            if (submission.userName == "Unknown Participant" || submission.userName.isEmpty || submission.userName == "Unknown") {
              submission.userName = await _fetchUserName(submission.userId);
            }
            await _updateReliabilityScore(submission.userId, -20, "No Re-upload After Rejection", projectTitle: projectTitle);
            updated = true;
          }
        }

        // Mark participants without submissions as missed
        Set<String> submittedUserIds = milestone.submissions.map((s) => s.userId).toSet();
        print("📋 Participants who submitted: ${submittedUserIds.join(', ')}");

        for (String participantId in activeParticipants) {
          if (!submittedUserIds.contains(participantId)) {
            int existingMissedIndex = milestone.submissions.indexWhere(
                    (s) => s.userId == participantId && s.status == 'missed'
            );

            if (existingMissedIndex == -1) {
              print("   ⚠️ Missing submission for participant: $participantId - creating missed submission");

              // Fetch actual user name from Firestore using helper
              final userName = await _fetchUserName(participantId);
              print("   👤 Fetched user name: $userName");

              await _updateReliabilityScore(participantId, -20, "No Show", projectTitle: projectTitle);
              milestone.submissions.add(MilestoneSubmission(
                userId: participantId,
                userName: userName,
                expenseClaimed: "0",
                proofImageUrl: "",
                status: "missed",
                rejectionReason: "System: No submission before due date",
                submittedAt: DateTime.now(),
              ));
              updated = true;
              print("   ✅ Created missed submission for $participantId");
            } else {
              print("   ℹ️ Participant $participantId already has a missed submission");
            }
          }
        }

        if (updated) {
          print("💾 Saving to Firestore...");
          await projectRef.update({
            'milestones': milestones.map((m) => m.toJson()).toList()
          });
          print("✅ SUCCESS: Updated Firestore with missing submissions for milestone $milestoneIndex");
          print("📊 Total submissions now: ${milestone.submissions.length}");
        } else {
          print("ℹ️ No updates needed for milestone $milestoneIndex (all participants already have submissions)");
        }
      } else {
        if (milestone.submissionDueDate == null) {
          print("ℹ️ No due date set for milestone $milestoneIndex");
        } else {
          print("ℹ️ Due date not passed yet for milestone $milestoneIndex");
          print("   Due (UTC): $dueDateUtc, Now (UTC): $nowUtc");
        }
      }
    } else {
      print("❌ Invalid milestone index: $milestoneIndex (total milestones: ${milestones.length})");
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
        // Update name if it's unknown or empty
        if (milestone.submissions[subIndex].userName == "Unknown Participant" ||
            milestone.submissions[subIndex].userName.isEmpty ||
            milestone.submissions[subIndex].userName == "Unknown") {
          milestone.submissions[subIndex].userName = await _fetchUserName(submissionUserId);
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
        // Update name if it's unknown or empty
        if (milestone.submissions[subIndex].userName == "Unknown Participant" ||
            milestone.submissions[subIndex].userName.isEmpty ||
            milestone.submissions[subIndex].userName == "Unknown") {
          milestone.submissions[subIndex].userName = await _fetchUserName(userId);
        }

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