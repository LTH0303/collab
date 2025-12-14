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

  // Start listening to the project document
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

  // Stop listening when leaving the page
  @override
  void dispose() {
    _projectSubscription?.cancel();
    super.dispose();
  }

  // --- CALCULATIONS & GETTERS ---

  // Check if project is started (Phase 1 is open or completed)
  bool get isProjectStarted {
    if (_project == null || _project!.milestones.isEmpty) return false;
    // It is started if the first milestone is NOT locked
    return _project!.milestones[0].isOpen || _project!.milestones[0].isCompleted;
  }

  // Calculate Milestone Progress (%)
  double get milestoneProgress {
    if (_project == null || _project!.milestones.isEmpty) return 0.0;
    int completed = _project!.milestones.where((m) => m.isCompleted).length;
    return (completed / _project!.milestones.length) * 100;
  }

  // Calculate Youth Participation (%)
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

  // --- ACTIONS ---

  // START PROJECT
  Future<void> startProject(String projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dbService.startProject(projectId);
      // Stream will update the UI
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveSubmission(String projectId, int milestoneIndex, String userId, {String? comment}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dbService.reviewMilestoneSubmission(projectId, milestoneIndex, userId, true, comment);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectSubmission(String projectId, int milestoneIndex, String userId, String reason) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dbService.reviewMilestoneSubmission(projectId, milestoneIndex, userId, false, reason);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

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
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}