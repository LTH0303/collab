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
  // 扩展此方法以触发监听器，在编辑页面直接修改了 Project 对象后调用此方法刷新 UI
  void updateDraft(int index) {
    if (index >= 0 && index < _drafts.length) {
      // 实际上在 EditProjectPage 中我们直接修改了 _drafts[index] 的引用对象
      // 这里只需要通知 Listeners 即可
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