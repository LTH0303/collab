// lib/models/ProjectRepository/i_project_repository.dart

import '../../models/project_model.dart';

/// 抽象仓库接口
/// 定义了 AI 资源推荐模块所需的核心业务行为
/// 遵循依赖倒置原则 (Dependency Inversion Principle)
abstract class IProjectRepository {

  // 1. 获取 AI 推荐方案
  Future<Project> getAIRecommendation(String resources);

  // 2. 发布项目到数据库
  Future<void> publishProject(Project project);
}