// lib/models/ProjectRepository/application_state.dart

import 'package:flutter/material.dart';
import 'i_application_repository.dart';
import 'application_model.dart';

/// Context Interface
abstract class ApplicationContext {
  IApplicationRepository get repository;
}

/// Abstract State
abstract class ApplicationState {
  Color get displayColor;
  String get labelText;
  String get participantButtonText;
  bool get isLeaderActionable; // Can leader approve/reject?
  bool get isParticipantActionable; // Can participant withdraw?

  // Actions
  Future<void> approve(Application app, IApplicationRepository repo);
  Future<void> reject(Application app, IApplicationRepository repo);

  // Factory to get state from string
  static ApplicationState fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return ApprovedState();
      case 'rejected':
        return RejectedState();
      case 'withdrawn':
        return WithdrawnState();
      case 'pending':
      default:
        return PendingState();
    }
  }
}

class PendingState extends ApplicationState {
  @override
  Color get displayColor => Colors.orange;
  @override
  String get labelText => "Pending Review";
  @override
  String get participantButtonText => "Pending";
  @override
  bool get isLeaderActionable => true;
  @override
  bool get isParticipantActionable => true; // Allows Withdraw

  @override
  Future<void> approve(Application app, IApplicationRepository repo) async {
    await repo.approveApplication(app);
  }

  @override
  Future<void> reject(Application app, IApplicationRepository repo) async {
    await repo.rejectApplication(app.id!);
  }
}

class ApprovedState extends ApplicationState {
  @override
  Color get displayColor => Colors.green;
  @override
  String get labelText => "Hired";
  @override
  String get participantButtonText => "Hired";
  @override
  bool get isLeaderActionable => false;
  @override
  bool get isParticipantActionable => false;

  @override
  Future<void> approve(Application app, IApplicationRepository repo) async {
    throw Exception("Application is already approved.");
  }

  @override
  Future<void> reject(Application app, IApplicationRepository repo) async {
    throw Exception("Cannot reject an already hired applicant directly.");
  }
}

class RejectedState extends ApplicationState {
  @override
  Color get displayColor => Colors.red;
  @override
  String get labelText => "Rejected";
  @override
  String get participantButtonText => "Rejected";
  @override
  bool get isLeaderActionable => false;
  @override
  bool get isParticipantActionable => false;

  @override
  Future<void> approve(Application app, IApplicationRepository repo) async {
    throw Exception("Cannot approve a rejected application.");
  }

  @override
  Future<void> reject(Application app, IApplicationRepository repo) async {
    throw Exception("Application is already rejected.");
  }
}

class WithdrawnState extends ApplicationState {
  @override
  Color get displayColor => Colors.grey;
  @override
  String get labelText => "Withdrawn";
  @override
  String get participantButtonText => "Withdrawn";

  @override
  bool get isLeaderActionable => false;
  @override
  bool get isParticipantActionable => false;

  @override
  Future<void> approve(Application app, IApplicationRepository repo) async {
    throw Exception("Cannot approve a withdrawn application.");
  }

  @override
  Future<void> reject(Application app, IApplicationRepository repo) async {
    throw Exception("Cannot reject a withdrawn application.");
  }
}