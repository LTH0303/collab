// lib/models/application_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  String? id;
  String projectId;
  String projectTitle;
  String applicantId;
  String applicantName;
  String leaderId;
  String status; // 'pending', 'approved', 'rejected', 'withdrawn'
  DateTime appliedAt;

  Application({
    this.id,
    required this.projectId,
    required this.projectTitle,
    required this.applicantId,
    required this.applicantName,
    required this.leaderId,
    this.status = 'pending',
    required this.appliedAt,
  });

  factory Application.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Application(
      id: docId,
      projectId: json['project_id'] ?? '',
      projectTitle: json['project_title'] ?? '',
      applicantId: json['applicant_id'] ?? '',
      applicantName: json['applicant_name'] ?? '',
      leaderId: json['leader_id'] ?? '',
      status: json['status'] ?? 'pending',
      appliedAt: (json['applied_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'project_title': projectTitle,
      'applicant_id': applicantId,
      'applicant_name': applicantName,
      'leader_id': leaderId,
      'status': status,
      'applied_at': Timestamp.fromDate(appliedAt),
    };
  }
}