// lib/ViewModel/ApplicationViewModel/application_view_model.dart

import 'package:flutter/material.dart';
import '../../models/ProjectRepository/i_application_repository.dart';
import '../../models/ProjectRepository/application_model.dart'; // Updated import
import '../../models/ProjectRepository/project_model.dart'; // Updated import
import '../../models/DatabaseService/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplicationViewModel extends ChangeNotifier {
  final IApplicationRepository _repo;
  final DatabaseService _dbService = DatabaseService();

  ApplicationViewModel(this._repo);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- PARTICIPANT ACTIONS ---

  Future<bool> applyForJob(Project project) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = "User not logged in";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String applicantName = user.displayName ?? user.email ?? "Unknown";

      final app = Application(
        projectId: project.id!,
        projectTitle: project.title,
        applicantId: user.uid,
        applicantName: applicantName,
        leaderId: project.leaderId ?? '',
        appliedAt: DateTime.now(),
      );

      await _repo.applyForJob(app);

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> getApplicationStatusForProject(String projectId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await _dbService.getApplicationStatus(user.uid, projectId);
  }

  // --- LEADER ACTIONS ---

  Stream<List<Application>> getLeaderApplications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    return _repo.getLeaderApplications(user.uid);
  }

  Stream<List<Application>> getProjectApplications(String projectId) {
    return _repo.getProjectApplications(projectId);
  }

  Stream<List<Application>> getProjectHiredList(String projectId) {
    return _repo.getProjectApprovedApplications(projectId);
  }

  Future<void> approveApplicant(Application app) async {
    _isLoading = true;
    notifyListeners();
    try {
      await app.state.approve(app, _repo);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectApplicant(Application app) async {
    _isLoading = true;
    notifyListeners();
    try {
      await app.state.reject(app, _repo);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}