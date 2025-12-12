// lib/viewmodels/PlannerViewModel/planner_view_model.dart

import 'package:flutter/material.dart';
import '../../models/ProjectRepository/project_repository.dart';
import '../../models/project_model.dart';

class PlannerViewModel extends ChangeNotifier {
  final ProjectRepository _repository;

  PlannerViewModel(this._repository);

  Project? _currentDraft; // AI 生成的草稿
  bool _isLoading = false;
  String? _error;

  Project? get currentDraft => _currentDraft;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ACTION: 生成方案 (对应 Image 1)
  Future<void> generatePlan(String resources) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentDraft = await _repository.getAIRecommendation(resources);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ACTION: 更新标题 (对应 Image 4 编辑)
  void updateTitle(String val) {
    _currentDraft?.title = val;
    notifyListeners();
  }

  // ACTION: 更新描述
  void updateDescription(String val) {
    _currentDraft?.description = val;
    notifyListeners();
  }

  // ACTION: 发布项目 (对应 Image 2 Publish)
  Future<void> publishCurrentDraft() async {
    if (_currentDraft == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.publishProject(_currentDraft!);
      _currentDraft = null; // 发布成功后清空草稿
    } catch (e) {
      _error = "Publish failed: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}