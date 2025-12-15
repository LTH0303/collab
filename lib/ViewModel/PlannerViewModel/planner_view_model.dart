// lib/ViewModel/PlannerViewModel/planner_view_model.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ProjectRepository/i_project_repository.dart';
import '../../models/ProjectRepository/project_model.dart';
import '../../models/DatabaseService/database_service.dart'; // Direct DB access for count

class PlannerViewModel extends ChangeNotifier {
  final IProjectRepository _repository;
  // We might need direct DB service for count checks if not in Repo interface,
  // or add count method to Interface. For speed, injecting DB Service here is acceptable.
  final DatabaseService _dbService = DatabaseService();

  PlannerViewModel(this._repository);

  final List<Project> _drafts = [];
  bool _isLoading = false;
  String? _error;

  List<Project> get drafts => _drafts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Action: Generate Plan
  Future<void> generatePlan(String resources, String budget) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Project newDraft = await _repository.getAIRecommendation(resources, budget);
      _drafts.add(newDraft);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateDraft(int index) {
    // 因为在编辑页面是直接修改引用的 Project 对象，
    // 所以这里只需要调用 notifyListeners() 来刷新 UI 即可。
    notifyListeners();
  }
  // Action: Publish with Constraint (Max 3)
  Future<void> publishDraft(int index) async {
    if (index < 0 || index >= _drafts.length) return;

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

      // 2. Publish (Pass leader ID inside project object or handled by repo)
      // We need to ensure the Repo uses the leader ID.
      // Ideally update Repo interface, but for now we can update the draft object if needed
      // or assume Repo handles the "addProject(project, leaderId)" call.

      // FIX: Since IProjectRepository.publishProject(project) doesn't take ID,
      // let's assume we call _dbService directly here or update the repo.
      // Let's go direct to DB service to match the updated method signature above.
      await _dbService.addProject(_drafts[index], user.uid);

      _drafts.removeAt(index);
      _error = null; // Clear any previous errors

    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", ""); // Clean error msg
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeDraft(int index) {
    if (index >= 0 && index < _drafts.length) {
      _drafts.removeAt(index);
      notifyListeners();
    }
  }
}