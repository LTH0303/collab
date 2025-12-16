import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/DatabaseService/database_service.dart';
import '../../models/ProjectRepository/project_model.dart';

class ImpactOverviewViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Project> _projects = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<Project>>? _sub;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Project> get projects => _projects;

  ImpactOverviewViewModel() {
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = "User not logged in";
      _isLoading = false;
      notifyListeners();
      return;
    }

    _sub = _dbService.streamLeaderAllProjects(user.uid).listen(
          (data) {
        _projects = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // --- Top Metrics ---

  Iterable<Project> get _completedProjects =>
      _projects.where((p) => p.status == 'completed');

  Iterable<Project> get _activeProjects =>
      _projects.where((p) => p.status == 'active');

  int get totalYouthParticipated {
    final ids = <String>{};
    for (final p in _completedProjects) {
      ids.addAll(p.activeParticipants);
    }
    return ids.length;
  }

  int get activeProjectsCount => _activeProjects.length;

  double get totalEconomicValue {
    double total = 0;
    for (final p in _completedProjects) {
      for (final m in p.milestones) {
        total += m.totalApprovedExpenses;
      }
    }
    return total;
  }

  int get completedProjectsCount => _completedProjects.length;

  // --- Monthly Progress Metrics ---

  DateTime get _now => DateTime.now();

  DateTime get _startOfMonth => DateTime(_now.year, _now.month, 1);

  DateTime get _startOfNextMonth =>
      DateTime(_now.year, _now.month + 1, 1); // Dart handles month overflow

  Iterable<Project> get _completedThisMonth => _completedProjects.where((p) {
    final completedAt = p.completedAt;
    if (completedAt == null) return false;
    return !completedAt.isBefore(_startOfMonth) &&
        completedAt.isBefore(_startOfNextMonth);
  });

  Iterable<Project> get _createdThisMonth => _projects.where((p) {
    final createdAt = p.createdAt;
    if (createdAt == null) return false;
    return !createdAt.isBefore(_startOfMonth) &&
        createdAt.isBefore(_startOfNextMonth);
  });

  double get projectCompletionRateThisMonth {
    final createdThisMonthCount = _createdThisMonth.length;
    if (createdThisMonthCount == 0) return 0;
    final completedThisMonthCount = _completedThisMonth.length;

    debugPrint('Total projects: ${_createdThisMonth.length}');
    debugPrint('Completed projects this month: ${_completedThisMonth.length}');

    return (completedThisMonthCount / createdThisMonthCount) * 100;
  }

  double get youthParticipationThisMonthPercent {
    final completedThisMonthProjects = _completedThisMonth.toList();
    if (completedThisMonthProjects.isEmpty) return 0;

    double totalKPI = 0;

    for (final p in completedThisMonthProjects) {
      int approvedCount = 0;
      int expectedCount = 0;

      for (final m in p.milestones) {
        approvedCount += m.submissions
            .where((s) => s.status == 'approved')
            .length;

        expectedCount += p.activeParticipants.length; // assume each participant expected once per milestone
      }

      final projectKPI = expectedCount > 0
          ? (approvedCount / expectedCount) * 100
          : 0;

      totalKPI += projectKPI;
    }

    return totalKPI / completedThisMonthProjects.length;
  }



  // Community growth this month vs last month (baseline hard-coded)
  int get communityGrowthThisMonth {
    int totalGrowth = 0;
    for (final p in _completedThisMonth) {
      if (p.initialPopulation != null && p.currentPopulation != null) {
        int growth = p.currentPopulation! - p.initialPopulation!;
        debugPrint('Project: ${p.title}, Growth: $growth');
        totalGrowth += growth;
      }
    }
    debugPrint('Total community growth this month: $totalGrowth');
    return totalGrowth;
  }


  // Hard-coded last month growth baseline (for now)
  int get communityGrowthLastMonthBaseline => 50;

  double get communityGrowthThisMonthPercent {
    final baseline = communityGrowthLastMonthBaseline;
    if (baseline <= 0) return 0;
    return (communityGrowthThisMonth / baseline) * 100;
  }
}


