// lib/ViewModel/JobViewModule/job_view_model.dart

import 'package:flutter/material.dart';
import '../../models/DatabaseService/database_service.dart';
import '../../models/project_model.dart';

class JobViewModel extends ChangeNotifier {
  final DatabaseService _dbService;

  JobViewModel(this._dbService);

  /// 暴露给 UI 的流
  /// 当数据库中有新的 active 项目添加时，这个流会自动更新
  Stream<List<Project>> get activeProjectsStream {
    return _dbService.getActiveProjects();
  }
}