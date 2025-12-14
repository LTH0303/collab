// lib/models/ProjectRepository/project_repository.dart

import 'package:firebase_auth/firebase_auth.dart'; // Import this
import '../AIService/ai_service.dart';
import '../DatabaseService/database_service.dart';
import 'project_model.dart';
import 'i_project_repository.dart';

/// The specific implementation of the Repository.
/// This acts as the bridge between the ViewModel and your Services (AI & DB).
class ProjectRepository implements IProjectRepository {
  final AIService _aiService;
  final DatabaseService _dbService;

  // Dependency Injection via Constructor
  ProjectRepository(this._aiService, this._dbService);

  @override
  Future<Project> getAIRecommendation(String resources, String budget) async {
    // 1. Call the AI Service
    return await _aiService.generateProjectDraft(resources, budget);
  }

  @override
  Future<void> publishProject(Project project) async {
    // 1. Get Current User (Leader) ID
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User must be logged in to publish a project.");
    }

    // 2. Set status to active
    project.status = 'active';

    // 3. Save to Firestore via DatabaseService, passing the Leader ID
    await _dbService.addProject(project, user.uid);
  }
}