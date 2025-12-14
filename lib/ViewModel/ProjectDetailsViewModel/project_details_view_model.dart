// lib/ViewModel/ProjectDetailsViewModel/project_details_view_model.dart

import 'dart:async'; // Import for StreamSubscription
import 'package:flutter/material.dart';
import '../../models/ProjectRepository/project_model.dart';
import '../../models/DatabaseService/database_service.dart';

class ProjectDetailsViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  Project? _project;
  bool _isLoading = false;
  String? _error;

  // Manage the subscription internally
  StreamSubscription<Project?>? _projectSubscription;

  Project? get project => _project;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- INITIALIZATION ---

  void listenToProject(String projectId) {
    _isLoading = true;
    _error = null;

    _projectSubscription?.cancel();
    _projectSubscription = _dbService.streamProject(projectId).listen(
          (updatedProject) {
        _project = updatedProject;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void setProject(Project project) {
    _project = project;
    notifyListeners();
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    super.dispose();
  }

  // --- CALCULATIONS & GETTERS ---

  bool get isProjectStarted {
    if (_project == null || _project!.milestones.isEmpty) return false;
    return _project!.milestones[0].isOpen || _project!.milestones[0].isCompleted;
  }

  double get milestoneProgress {
    if (_project == null || _project!.milestones.isEmpty) return 0.0;
    int completed = _project!.milestones.where((m) => m.isCompleted).length;
    return (completed / _project!.milestones.length) * 100;
  }

  double get youthParticipation {
    if (_project == null || _project!.activeParticipants.isEmpty) return 0.0;

    int totalParticipants = _project!.activeParticipants.length;
    int currentMilestoneIndex = _project!.milestones.indexWhere((m) => m.isOpen);

    int milestonesToCount = currentMilestoneIndex == -1
        ? _project!.milestones.length
        : currentMilestoneIndex + 1;

    int totalExpected = totalParticipants * milestonesToCount;
    if (totalExpected == 0) return 0.0;

    int totalSubmissions = 0;
    for (int i = 0; i < milestonesToCount && i < _project!.milestones.length; i++) {
      totalSubmissions += _project!.milestones[i].submissions
          .where((s) => s.status != 'pending')
          .length;
    }

    return (totalSubmissions / totalExpected) * 100;
  }

  int get totalPendingSubmissions {
    if (_project == null) return 0;
    return _project!.milestones.fold(0, (sum, m) => sum + m.pendingSubmissionsCount);
  }

  bool get isProjectCompleted {
    if (_project == null || _project!.milestones.isEmpty) return false;
    return _project!.milestones.every((m) => m.isCompleted);
  }

  // --- ACTIONS (With Optimistic Updates) ---

  Future<void> startProject(String projectId) async {
    // 1. Optimistic Update
    if (_project != null && _project!.milestones.isNotEmpty) {
      _project!.milestones[0].status = 'open';
      notifyListeners();
    }

    // 2. DB Call
    try {
      await _dbService.startProject(projectId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> approveSubmission(String projectId, int milestoneIndex, String userId, {String? comment}) async {
    // 1. Optimistic Update
    if (_project != null && milestoneIndex < _project!.milestones.length) {
      try {
        final milestone = _project!.milestones[milestoneIndex];
        final subIndex = milestone.submissions.indexWhere((s) => s.userId == userId);
        if (subIndex != -1) {
          milestone.submissions[subIndex].status = 'approved';
          notifyListeners(); // Update UI immediately
        }
      } catch (e) {
        print("Optimistic update failed: $e");
      }
    }

    // 2. DB Call
    try {
      await _dbService.reviewMilestoneSubmission(projectId, milestoneIndex, userId, true, comment);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectSubmission(String projectId, int milestoneIndex, String userId, String reason) async {
    // 1. Optimistic Update
    if (_project != null && milestoneIndex < _project!.milestones.length) {
      try {
        final milestone = _project!.milestones[milestoneIndex];
        final subIndex = milestone.submissions.indexWhere((s) => s.userId == userId);
        if (subIndex != -1) {
          milestone.submissions[subIndex].status = 'rejected';
          milestone.submissions[subIndex].rejectionReason = reason;
          notifyListeners(); // Update UI immediately
        }
      } catch (e) {
        print("Optimistic update failed: $e");
      }
    }

    // 2. DB Call
    try {
      await _dbService.reviewMilestoneSubmission(projectId, milestoneIndex, userId, false, reason);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> completeMilestone(String projectId, int milestoneIndex) async {
    if (_project == null) return;

    // 1. Optimistic Update
    if (milestoneIndex < _project!.milestones.length) {
      _project!.milestones[milestoneIndex].status = 'completed';
      if (milestoneIndex + 1 < _project!.milestones.length) {
        _project!.milestones[milestoneIndex + 1].status = 'open';
      }
      notifyListeners();
    }

    try {
      await _dbService.completeMilestone(projectId, milestoneIndex);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}