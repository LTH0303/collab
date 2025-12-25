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
    final growth = currentPopulation! - initialPopulation!;
    final maxGrowth = youthParticipated; // Community growth cannot exceed number of youth participants
    // Return the growth, but capped at the number of youth participants
    return growth > maxGrowth ? maxGrowth : growth;
  }

  // --- Population Updates ---

  Future<void> savePopulation(
      String projectId, {
        int? newInitialPopulation,
        int? newCurrentPopulation,
      }) async {
    if (newInitialPopulation == null && newCurrentPopulation == null) return;

    // Determine the final values (use existing if new value is null)
    final finalInitial = newInitialPopulation ?? project.initialPopulation;
    final finalCurrent = newCurrentPopulation ?? project.currentPopulation;

    // Validate: Community growth (current - initial) must not exceed youth participants
    if (finalInitial != null && finalCurrent != null) {
      final growth = finalCurrent - finalInitial;
      if (growth > youthParticipated) {
        throw Exception(
            "Community growth ($growth) cannot exceed the number of youth participants ($youthParticipated). "
                "Please adjust the population values."
        );
      }
    }

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

  Future<void> saveActualOutcomes(String projectId, List<String> actualOutcomes) async {
    project.actualOutcomes = actualOutcomes;
    await _dbService.updateProjectOutcomes(projectId, actualOutcomes);
    notifyListeners();
  }
}


