// lib/models/ProjectRepository/i_application_repository.dart

import 'application_model.dart';

abstract class IApplicationRepository {
  Future<void> applyForJob(Application app);
  Stream<List<Application>> getLeaderApplications(String leaderId);
  Stream<List<Application>> getProjectApplications(String projectId);
  Stream<List<Application>> getProjectApprovedApplications(String projectId); // NEW
  Future<void> approveApplication(Application app);
  Future<void> rejectApplication(String applicationId);
}