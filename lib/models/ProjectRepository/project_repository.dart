// lib/models/ProjectRepository/project_repository.dart

import '../AIService/ai_service.dart';
import '../DatabaseService/database_service.dart';
import '../../models/project_model.dart';

class ProjectRepository {
  final AIService _aiService;
  final DatabaseService _dbService;

  ProjectRepository(this._aiService, this._dbService);

  // 1. 找 AI 要方案
  Future<Project> getAIRecommendation(String resources) async {
    return await _aiService.generateProjectDraft(resources);
  }

  // 2. 找 Firebase 存数据
  Future<void> publishProject(Project project) async {
    return await _dbService.addProject(project);
  }
}