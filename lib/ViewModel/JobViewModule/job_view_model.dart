// lib/viewmodels/JobViewModule/job_view_model.dart

import 'package:flutter/material.dart';
import '../../models/DatabaseService/database_service.dart'; // 引用你的数据库服务
import '../../models/project_model.dart'; // 引用项目模型

class JobViewModel extends ChangeNotifier {
  final DatabaseService _dbService;

  JobViewModel(this._dbService);

  // 使用 Stream (流) 来实时监听数据库变化
  // 只要村长那边一按 "Publish"，这里不需要刷新也会自动弹出来
  Stream<List<Project>> get activeProjectsStream {
    return _dbService.getActiveProjects();
  }
}