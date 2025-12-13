// lib/models/ProjectRepository/i_project_repository.dart

import '../../models/project_model.dart';

/// Abstract Interface for Project Repository
/// Defines the business capabilities.
abstract class IProjectRepository {
  // 1. Get AI Recommendation with Budget
  Future<Project> getAIRecommendation(String resources, String budget);

  // 2. Publish Project to Database
  Future<void> publishProject(Project project);
}