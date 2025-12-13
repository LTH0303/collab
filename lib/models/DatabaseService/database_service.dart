// lib/models/DatabaseService/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/project_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 发布项目：将 Draft 存入 Firestore 'projects' 集合
  /// 这一步由 Village Leader 触发
  Future<void> addProject(Project project) async {
    project.status = 'active'; // 关键：发布时强制将状态设为 'active'
    await _db.collection('projects').add(project.toJson());
  }

  /// 获取所有 'active' 状态的项目
  /// 这一步由 Youth Participant 使用，确保他们看不到 'draft'
  Stream<List<Project>> getActiveProjects() {
    return _db.collection('projects')
        .where('status', isEqualTo: 'active') // 关键过滤条件
        .orderBy('created_at', descending: true) // 可选：按时间倒序排列，最新的在前
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromJson(doc.data(), docId: doc.id))
        .toList());
  }
}