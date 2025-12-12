// lib/viewmodels/PlannerViewModel/planner_view_model.dart

import 'package:flutter/material.dart';
import '../../models/ProjectRepository/project_repository.dart';
import '../../models/project_model.dart';

class PlannerViewModel extends ChangeNotifier {
  final ProjectRepository _repository;

  PlannerViewModel(this._repository);

  // 🔴 关键修改：将单一 Draft 改为 List，支持存放多个方案
  final List<Project> _drafts = [];

  bool _isLoading = false;
  String? _error;

  List<Project> get drafts => _drafts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ACTION: 生成方案 (会添加到 Drafts 列表的末尾)
  Future<void> generatePlan(String resources) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Project newDraft = await _repository.getAIRecommendation(resources);
      _drafts.add(newDraft); // 追加到列表
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
      // 创建一个新的 Project 对象以触发更新（或者直接修改属性，但在 Dart 中如果 Project 是 final 字段较多推荐 copyWith 模式）
      // 假设 Project 类没有 copyWith，直接修改属性：
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
      await _repository.publishProject(draftToPublish);

      // 发布成功后，从 Draft 列表中移除
      _drafts.removeAt(index);
    } catch (e) {
      _error = "Publish failed: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}