import 'package:flutter/material.dart';
import '../../models/ProjectRepository/project_model.dart';
import '../../models/DatabaseService/database_service.dart';

class CompletedProjectDashboardViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  Project project;

  CompletedProjectDashboardViewModel({required this.project});

  // --- Impact Metrics ---

  double get totalEconomicValue {
    return project.milestones.fold(
      0.0,
          (sum, m) => sum + m.totalApprovedExpenses,
    );
  }

  int get youthParticipated => project.activeParticipants.length;

  int? get initialPopulation => project.initialPopulation;
  int? get currentPopulation => project.currentPopulation;

  int? get communityGrowth {
    if (initialPopulation == null || currentPopulation == null) return null;
    return currentPopulation! - initialPopulation!;
  }

  // --- Population Updates ---

  Future<void> savePopulation(
      String projectId, {
        int? newInitialPopulation,
        int? newCurrentPopulation,
      }) async {
    if (newInitialPopulation == null && newCurrentPopulation == null) return;

    if (newInitialPopulation != null) {
      project.initialPopulation = newInitialPopulation;
    }
    if (newCurrentPopulation != null) {
      project.currentPopulation = newCurrentPopulation;
    }

    await _dbService.updateProjectPopulation(
      projectId,
      initialPopulation: newInitialPopulation,
      currentPopulation: newCurrentPopulation,
    );

    notifyListeners();
  }
}


