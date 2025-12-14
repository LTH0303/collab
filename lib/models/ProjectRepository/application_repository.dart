// lib/models/ProjectRepository/application_repository.dart

import '../DatabaseService/database_service.dart';
import 'application_model.dart';
import 'i_application_repository.dart';

class ApplicationRepository implements IApplicationRepository {
  final DatabaseService _dbService;

  ApplicationRepository(this._dbService);

  @override
  Future<void> applyForJob(Application app) async {
    bool hasActiveJob = await _dbService.hasActiveJob(app.applicantId);
    if (hasActiveJob) {
      throw Exception("You already have an active project. Complete it first.");
    }

    int pendingCount = await _dbService.countUserPendingApplications(app.applicantId);
    if (pendingCount >= 5) {
      throw Exception("You cannot have more than 5 active applications.");
    }

    bool alreadyApplied = await _dbService.hasAppliedToProject(app.applicantId, app.projectId);
    if (alreadyApplied) {
      throw Exception("You have already applied to this project.");
    }

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

  // NEW Implementation
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
}