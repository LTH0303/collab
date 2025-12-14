// lib/ViewModel/ProjectDetailsViewModel/project_details_view_model.dart

import 'package:flutter/material.dart';
import '../../models/ProjectRepository/project_model.dart';
import '../../models/DatabaseService/database_service.dart';

class ProjectDetailsViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  Project? _project;
  bool _isLoading = false;
  String? _error;

  Project? get project => _project;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setProject(Project project) {
    _project = project;
    notifyListeners();
  }

  // Calculate Milestone Progress (%)
  double get milestoneProgress {
    if (_project == null || _project!.milestones.isEmpty) return 0.0;
    int completed = _project!.milestones.where((m) => m.isCompleted).length;
    return (completed / _project!.milestones.length) * 100;
  }

  // Calculate Youth Participation (%)
  // Formula: (Total submissions completed) / (Total expected submissions up to current milestone)
  double get youthParticipation {
    if (_project == null || _project!.activeParticipants.isEmpty) return 0.0;

    int totalParticipants = _project!.activeParticipants.length;
    int currentMilestoneIndex = _project!.milestones.indexWhere((m) => m.isOpen);

    // If no open milestone, use all milestones
    int milestonesToCount = currentMilestoneIndex == -1
        ? _project!.milestones.length
        : currentMilestoneIndex + 1;

    int totalExpected = totalParticipants * milestonesToCount;
    if (totalExpected == 0) return 0.0;

    // Count all non-pending submissions up to current milestone
    int totalSubmissions = 0;
    for (int i = 0; i < milestonesToCount && i < _project!.milestones.length; i++) {
      totalSubmissions += _project!.milestones[i].submissions
          .where((s) => s.status != 'pending')
          .length;
    }

    return (totalSubmissions / totalExpected) * 100;
  }

  // Get total pending submissions count across all milestones
  int get totalPendingSubmissions {
    if (_project == null) return 0;
    return _project!.milestones.fold(0, (sum, m) => sum + m.pendingSubmissionsCount);
  }

  // Check if project is completed (all milestones completed)
  bool get isProjectCompleted {
    if (_project == null || _project!.milestones.isEmpty) return false;
    return _project!.milestones.every((m) => m.isCompleted);
  }

  // Get current active milestone index
  int? get currentActiveMilestoneIndex {
    if (_project == null) return null;
    return _project!.milestones.indexWhere((m) => m.isOpen);
  }

  // Approve submission
  Future<void> approveSubmission(String projectId, int milestoneIndex, String userId, {String? comment}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dbService.reviewMilestoneSubmission(projectId, milestoneIndex, userId, true, comment);
      await _refreshProject(projectId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reject submission
  Future<void> rejectSubmission(String projectId, int milestoneIndex, String userId, String reason) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dbService.reviewMilestoneSubmission(projectId, milestoneIndex, userId, false, reason);
      await _refreshProject(projectId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark submission as missed
  Future<void> markSubmissionAsMissed(String projectId, int milestoneIndex, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dbService.markSubmissionAsMissed(projectId, milestoneIndex, userId);
      await _refreshProject(projectId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Complete milestone (only if all submissions are reviewed)
  Future<void> completeMilestone(String projectId, int milestoneIndex) async {
    if (_project == null) return;

    final milestone = _project!.milestones[milestoneIndex];
    if (!milestone.canBeCompleted) {
      _error = "Cannot complete milestone: Some submissions are still pending review.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dbService.completeMilestone(projectId, milestoneIndex);
      await _refreshProject(projectId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh project data
  Future<void> _refreshProject(String projectId) async {
    try {
      final snapshot = await _dbService.getProjectById(projectId);
      if (snapshot != null) {
        _project = snapshot;
        notifyListeners();
      }
    } catch (e) {
      print("Error refreshing project: $e");
    }
  }

  // Stream project updates
  Stream<Project?> streamProject(String projectId) {
    return _dbService.streamProject(projectId);
  }
}

