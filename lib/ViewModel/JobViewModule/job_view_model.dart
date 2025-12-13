// lib/ViewModel/JobViewModule/job_view_model.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/DatabaseService/database_service.dart';
import '../../models/project_model.dart';

class JobViewModel extends ChangeNotifier {
  final DatabaseService _dbService;

  JobViewModel(this._dbService);

  bool _isApplying = false;
  String? _applyError;

  bool get isApplying => _isApplying;
  String? get applyError => _applyError;

  Stream<List<Project>> get activeProjectsStream {
    return _dbService.getActiveProjects();
  }

  // Action: Apply for Job (Constraint: Max 1)
  Future<bool> applyForJob(Project project) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _isApplying = true;
    _applyError = null;
    notifyListeners();

    try {
      // 1. Check if already has active job
      bool hasJob = await _dbService.hasActiveJob(user.uid);
      if (hasJob) {
        throw Exception("You already have an active project. Complete it first.");
      }

      // 2. Apply (Add user ID to project's 'active_participants' array)
      if (project.id != null) {
        await FirebaseFirestore.instance.collection('projects').doc(project.id).update({
          'active_participants': FieldValue.arrayUnion([user.uid])
        });
      }

      _isApplying = false;
      notifyListeners();
      return true;

    } catch (e) {
      _applyError = e.toString().replaceAll("Exception: ", "");
      _isApplying = false;
      notifyListeners();
      return false;
    }
  }

  // --- Submit Milestone Logic (Existing) ---
  Future<void> submitMilestoneExpense(Project project, int milestoneIndex, String amount) async {
    // ... existing implementation ...
    try {
      project.milestones[milestoneIndex].expenseClaimed = amount;
      project.milestones[milestoneIndex].isCompleted = true;

      if (project.id != null) {
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(project.id)
            .update({
          'milestones': project.milestones.map((m) => m.toJson()).toList(),
        });
      }
      notifyListeners();
    } catch (e) {
      print("Error submitting: $e");
    }
  }
}