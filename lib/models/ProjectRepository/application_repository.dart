// lib/models/ProjectRepository/application_repository.dart

import '../DatabaseService/database_service.dart';
import 'application_model.dart';
import 'i_application_repository.dart';

class ApplicationRepository implements IApplicationRepository {
  final DatabaseService _dbService;

  ApplicationRepository(this._dbService);

  @override
  Future<void> applyForJob(Application app) async {
    // 1. Global Checks
    bool hasActiveJob = await _dbService.hasActiveJob(app.applicantId);
    if (hasActiveJob) {
      throw Exception("You already have an active project. Complete it first.");
    }

    int pendingCount = await _dbService.countUserPendingApplications(app.applicantId);
    if (pendingCount >= 5) {
      throw Exception("You cannot have more than 5 active applications.");
    }

    // 2. Check for Existing Application
    Application? existingApp = await _dbService.getUserApplicationForProject(app.applicantId, app.projectId);

    if (existingApp != null) {
      // Handle Re-application logic
      if (existingApp.status == 'withdrawn') {
        // Reactivate: Update status 'withdrawn' -> 'pending'
        if (existingApp.id != null) {
          await _dbService.updateApplicationStatus(existingApp.id!, 'pending');
          return;
        }
      } else if (existingApp.status == 'rejected') {
        // Optional: Allow re-apply after rejection? For now, block.
        throw Exception("Your application was rejected. You cannot re-apply immediately.");
      } else {
        throw Exception("You have already applied to this project.");
      }
    }

    // 3. New Application
    await _dbService.addApplication(app);
  }

  @override
  Stream<List<Application>> getLeaderApplications(String leaderId) {
    return _dbService.getLeaderPendingApplications(leaderId);
  }

  @override
  Stream<List<Application>> getProjectApplications(String projectId) {
    return _dbService.getProjectPendingApplications(projectId);
  }

  @override
  Stream<List<Application>> getProjectApprovedApplications(String projectId) {
    return _dbService.getProjectApprovedApplications(projectId);
  }

  @override
  Future<void> approveApplication(Application app) async {
    await _dbService.approveApplicationTransaction(app);
  }

  @override
  Future<void> rejectApplication(String applicationId) async {
    await _dbService.updateApplicationStatus(applicationId, 'rejected');
  }

  @override
  Future<void> withdrawApplication(String applicationId) async {
    await _dbService.updateApplicationStatus(applicationId, 'withdrawn');
  }
}