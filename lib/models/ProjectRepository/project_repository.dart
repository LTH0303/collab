// lib/models/ProjectRepository/project_repository.dart

import '../AIService/ai_service.dart';
import '../DatabaseService/database_service.dart';
import '../../models/project_model.dart';
import 'i_project_repository.dart'; // 引入接口

/// 具体的仓库实现类
/// 充当 Facade (外观)，协调 AIService 和 DatabaseService
class ProjectRepository implements IProjectRepository {
  final AIService _aiService;
  final DatabaseService _dbService;

  // 构造函数注入依赖
  ProjectRepository(this._aiService, this._dbService);

  @override
  Future<Project> getAIRecommendation(String resources) async {
    // 调用 AI 服务生成草案
    return await _aiService.generateProjectDraft(resources);
  }

  @override
  Future<void> publishProject(Project project) async {
    // 调用数据库服务持久化数据
    return await _dbService.addProject(project);
  }
}