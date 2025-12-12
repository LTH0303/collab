// lib/models/DatabaseService/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/project_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 发布项目：将 Draft 存入 Firestore
  Future<void> addProject(Project project) async {
    project.status = 'active'; // 强制设为发布状态
    await _db.collection('projects').add(project.toJson());
  }

  // 获取所有项目 (给 Participants 用)
  Stream<List<Project>> getActiveProjects() {
    return _db.collection('projects')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromJson(doc.data(), docId: doc.id))
        .toList());
  }
}