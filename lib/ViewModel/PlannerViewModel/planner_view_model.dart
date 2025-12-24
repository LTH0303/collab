// lib/ViewModel/PlannerViewModel/planner_view_model.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ProjectRepository/i_project_repository.dart';
import '../../models/ProjectRepository/project_model.dart';
import '../../models/DatabaseService/database_service.dart';

class PlannerViewModel extends ChangeNotifier {
  final IProjectRepository _repository;
  final DatabaseService _dbService = DatabaseService();

  PlannerViewModel(this._repository);

  // We no longer keep a local list _drafts because UI will stream from Firestore
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- NEW: Clear Error Method ---
  void clearError() {
    _error = null;
    // We don't necessarily need to notifyListeners() here if called inside a build frame callback,
    // but it ensures the state is clean for the next cycle.
    notifyListeners();
  }

  // Action: Generate Plan and Save to DB as Draft
  Future<void> generatePlan(String resources, String budget) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User must be logged in to generate a plan");
      }

      // 1. Get AI Draft
      Project newDraft = await _repository.getAIRecommendation(resources, budget);

      // 2. Set status to 'draft' ensuring it doesn't go live yet
      newDraft.status = 'draft';

      // 3. Save directly to DB
      await _dbService.addProject(newDraft, user.uid);

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NEW: Manually Add Draft ---
  Future<void> addManualDraft(Project newDraft) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User must be logged in to add a draft");
      }

      // Ensure status is draft
      newDraft.status = 'draft';

      // Save to DB
      await _dbService.addProject(newDraft, user.uid);

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update existing draft in DB
  Future<void> updateDraft(String projectId, Map<String, dynamic> data) async {
    try {
      await _dbService.updateProjectDetails(projectId, data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Action: Publish existing draft (Status 'draft' -> 'active')
  Future<void> publishDraft(String projectId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = "User not logged in";
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Check Constraint
      int activeCount = await _dbService.countLeaderActiveProjects(user.uid);
      if (activeCount >= 3) {
        throw Exception("Limit Reached: You can only have 3 active projects at a time.");
      }

      // 2. Update Status to Active
      await _dbService.publishProjectFromDraft(projectId);

      _error = null;

    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove Draft from DB
  Future<void> removeDraft(String projectId) async {
    try {
      await _dbService.deleteProject(projectId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}