// lib/ViewModel/PlannerViewModel/planner_view_model.dart

import 'package:flutter/material.dart';
import '../../models/ProjectRepository/i_project_repository.dart'; // 依赖接口
import '../../models/project_model.dart';

class PlannerViewModel extends ChangeNotifier {
  // 依赖抽象接口，而不是具体类
  // 这使得 ViewModel 更容易进行单元测试（可以注入 MockRepository）
  final IProjectRepository _repository;

  PlannerViewModel(this._repository);

  final List<Project> _drafts = [];
  bool _isLoading = false;
  String? _error;

  List<Project> get drafts => _drafts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ACTION: 生成方案
  Future<void> generatePlan(String resources) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ViewModel 不关心数据是来自 Gemini 还是其他 AI，只管调用接口
      Project newDraft = await _repository.getAIRecommendation(resources);
      _drafts.add(newDraft);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ACTION: 更新指定的 Draft
  void updateDraft(int index, {String? title, String? description, List<Milestone>? milestones}) {
    if (index >= 0 && index < _drafts.length) {
      final oldDraft = _drafts[index];
      // 简单的状态更新
      if (title != null) oldDraft.title = title;
      if (description != null) oldDraft.description = description;
      if (milestones != null) oldDraft.milestones = milestones;

      notifyListeners();
    }
  }

  // ACTION: 删除 Draft
  void removeDraft(int index) {
    if (index >= 0 && index < _drafts.length) {
      _drafts.removeAt(index);
      notifyListeners();
    }
  }

  // ACTION: 发布指定索引的 Draft
  Future<void> publishDraft(int index) async {
    if (index < 0 || index >= _drafts.length) return;

    _isLoading = true;
    notifyListeners();

    try {
      final draftToPublish = _drafts[index];
      // 调用接口方法
      await _repository.publishProject(draftToPublish);

      // 发布成功后移除草稿
      _drafts.removeAt(index);
    } catch (e) {
      _error = "Publish failed: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}