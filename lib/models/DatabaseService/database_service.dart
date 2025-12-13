// lib/models/DatabaseService/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/project_model.dart';
import '../../models/application_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PROJECT METHODS ---

  Future<void> addProject(Project project, String leaderId) async {
    project.status = 'active';
    for (var m in project.milestones) {
      m.status = 'locked';
    }

    await _db.collection('projects').add({
      ...project.toJson(),
      'leader_id': leaderId,
      'created_at': DateTime.now().toIso8601String(),
      'active_participants': [],
    });
  }

  // Safe Start Project (No Transaction Crash)
  Future<void> startProject(String projectId) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);

    try {
      DocumentSnapshot snapshot = await projectRef.get();
      if (!snapshot.exists) throw Exception("Project not found");

      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) throw Exception("Project data is empty");

      List<dynamic> milestonesRaw = data['milestones'] ?? [];
      List<Milestone> milestones = milestonesRaw.map((m) => Milestone.fromJson(m)).toList();

      if (milestones.isNotEmpty) {
        milestones[0].status = 'open';
      } else {
        return;
      }

      await projectRef.update({
        'milestones': milestones.map((m) => m.toJson()).toList()
      });

    } catch (e) {
      print("Error starting project: $e");
      rethrow;
    }
  }

  // --- NEW: Unlock Next Phase Explicitly ---
  Future<void> unlockNextPhase(String projectId, int currentPhaseIndex) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);

    try {
      DocumentSnapshot snapshot = await projectRef.get();
      if (!snapshot.exists) throw Exception("Project not found");

      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) throw Exception("Project data is empty");

      List<dynamic> milestonesRaw = data['milestones'] ?? [];
      List<Milestone> milestones = milestonesRaw.map((m) => Milestone.fromJson(m)).toList();

      // Ensure next index exists
      int nextIndex = currentPhaseIndex + 1;
      if (nextIndex < milestones.length) {
        milestones[nextIndex].status = 'open';

        // Optional: Ensure current is marked completed if not already?
        // usually approval handles that, but good to be safe.
        if (milestones[currentPhaseIndex].status != 'completed') {
          milestones[currentPhaseIndex].status = 'completed';
        }

        await projectRef.update({
          'milestones': milestones.map((m) => m.toJson()).toList()
        });
      }
    } catch (e) {
      print("Error unlocking phase: $e");
      rethrow;
    }
  }

  // --- EXISTING METHODS ---

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

  // --- MILESTONE SUBMISSION FLOW ---

  Future<void> submitMilestone(String projectId, int milestoneIndex, String expense, String? photoUrl) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);

    DocumentSnapshot snapshot = await projectRef.get();
    if (!snapshot.exists) throw Exception("Project not found");

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<dynamic> rawMilestones = data['milestones'] ?? [];
    List<Milestone> milestones = rawMilestones.map((m) => Milestone.fromJson(m)).toList();

    if (milestoneIndex < milestones.length) {
      milestones[milestoneIndex].expenseClaimed = expense;
      milestones[milestoneIndex].proofImageUrl = photoUrl;
      milestones[milestoneIndex].status = 'pending_review';
      milestones[milestoneIndex].rejectionReason = null;

      await projectRef.update({
        'milestones': milestones.map((m) => m.toJson()).toList()
      });
    }
  }

  // UPDATED: Only approves the submission, DOES NOT unlock next phase automatically
  Future<void> approveMilestone(String projectId, int milestoneIndex) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);

    DocumentSnapshot snapshot = await projectRef.get();
    if (!snapshot.exists) throw Exception("Project not found");

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<dynamic> rawMilestones = data['milestones'] ?? [];
    List<Milestone> milestones = rawMilestones.map((m) => Milestone.fromJson(m)).toList();

    if (milestoneIndex < milestones.length) {
      milestones[milestoneIndex].status = 'completed';
      // Next phase unlocking is removed from here

      await projectRef.update({
        'milestones': milestones.map((m) => m.toJson()).toList(),
      });
    }
  }

  Future<void> rejectMilestone(String projectId, int milestoneIndex, String reason) async {
    DocumentReference projectRef = _db.collection('projects').doc(projectId);

    DocumentSnapshot snapshot = await projectRef.get();
    if (!snapshot.exists) throw Exception("Project not found");

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<dynamic> rawMilestones = data['milestones'] ?? [];
    List<Milestone> milestones = rawMilestones.map((m) => Milestone.fromJson(m)).toList();

    if (milestoneIndex < milestones.length) {
      milestones[milestoneIndex].status = 'rejected';
      milestones[milestoneIndex].rejectionReason = reason;

      await projectRef.update({
        'milestones': milestones.map((m) => m.toJson()).toList()
      });
    }
  }

  // --- APPLICATION METHODS ---

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
    return {
      'name': 'Youth Participant',
      'email': 'email@example.com',
      'skills': ['Farming', 'Labor'],
      'reliability': 'High'
    };
  }
}