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
  String? _currentLeaderId; // Store current leader ID for validation

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

    _currentLeaderId = user.uid; // Store leader ID for validation

    _sub = _dbService.streamLeaderAllProjects(user.uid).listen(
          (data) {
        // Additional validation: ensure all projects belong to the current leader
        // This is a defensive check in case of data inconsistency
        final filteredProjects = data.where((project) {
          // Double-check that project.leaderId matches current leader
          // (This should already be filtered by the database query, but we validate here too)
          return project.leaderId == _currentLeaderId;
        }).toList();

        _projects = filteredProjects;
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
  // All calculations explicitly filter by current leader ID to ensure data integrity

  Iterable<Project> get _completedProjects =>
      _projects.where((p) => p.status == 'completed' && p.leaderId == _currentLeaderId);

  Iterable<Project> get _activeProjects =>
      _projects.where((p) => p.status == 'active' && p.leaderId == _currentLeaderId);

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
    // Additional leader ID validation for monthly calculations
    if (p.leaderId != _currentLeaderId) return false;
    final completedAt = p.completedAt;
    if (completedAt == null) return false;
    return !completedAt.isBefore(_startOfMonth) &&
        completedAt.isBefore(_startOfNextMonth);
  });

  Iterable<Project> get _createdThisMonth => _projects.where((p) {
    // Additional leader ID validation for monthly calculations
    if (p.leaderId != _currentLeaderId) return false;
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
  // Community growth per project is capped at the number of youth participants
  int get communityGrowthThisMonth {
    int totalGrowth = 0;
    for (final p in _completedThisMonth) {
      if (p.initialPopulation != null && p.currentPopulation != null) {
        int growth = p.currentPopulation! - p.initialPopulation!;
        final maxGrowth = p.activeParticipants.length; // Cap at youth participants
        // Cap the growth to not exceed youth participants
        final cappedGrowth = growth > maxGrowth ? maxGrowth : growth;
        debugPrint('Project: ${p.title}, Growth: $growth (capped to $cappedGrowth, max: $maxGrowth)');
        totalGrowth += cappedGrowth;
      }
    }
    debugPrint('Total community growth this month: $totalGrowth');
    return totalGrowth;
  }


  // Hard-coded last month growth baseline (for now)
  int get communityGrowthLastMonthBaseline => 50;

  // Formula: (thisMonth - lastMonth) / lastMonth * 100
  // Can be positive, negative, zero, or >= 100%
  double get communityGrowthThisMonthPercent {
    final lastMonth = communityGrowthLastMonthBaseline;
    final thisMonth = communityGrowthThisMonth;

    // If last month is 0, we can't calculate percentage
    if (lastMonth <= 0) {
      // If this month also has 0, return 0%
      if (thisMonth == 0) return 0;
      // If this month has growth but last month was 0, return a high percentage (or could be 100%+)
      return 100.0;
    }

    // Formula: (thisMonth - lastMonth) / lastMonth * 100
    final percent = ((thisMonth - lastMonth) / lastMonth) * 100;
    debugPrint('Community growth: $percent% (thisMonth: $thisMonth, lastMonth: $lastMonth)');
    return percent;
  }
}


