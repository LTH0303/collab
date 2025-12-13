// lib/models/project_model.dart

class Project {
  String? id;
  String title;
  String description;
  String timeline;       // e.g. "3-4 Months"
  List<String> skills;   // e.g. ["Agriculture", "Construction"]
  String participantRange; // e.g. "5-8 participants"
  List<Milestone> milestones;
  String status;         // 'draft' or 'active'
  List<String> startingResources; // New: 起始物资
  String address;        // New: 项目地址

  Project({
    this.id,
    required this.title,
    required this.description,
    required this.timeline,
    required this.skills,
    required this.participantRange,
    required this.milestones,
    this.status = 'draft',
    this.startingResources = const [],
    this.address = '',
  });

  // 从 AI 生成的 JSON 或 Firebase 数据转换
  factory Project.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Project(
      id: docId,
      title: json['project_title'] ?? '',
      description: json['description'] ?? '',
      timeline: json['timeline'] ?? '',
      skills: List<String>.from(json['required_skills'] ?? []),
      participantRange: json['participant_range'] ?? '',
      status: json['status'] ?? 'draft',
      startingResources: List<String>.from(json['starting_resources'] ?? []),
      address: json['address'] ?? '',
      milestones: (json['milestones'] as List? ?? [])
          .map((m) => Milestone.fromJson(m))
          .toList(),
    );
  }

  // 转换为 JSON 上传 Firebase
  Map<String, dynamic> toJson() {
    return {
      'project_title': title,
      'description': description,
      'timeline': timeline,
      'required_skills': skills,
      'participant_range': participantRange,
      'status': status,
      'starting_resources': startingResources,
      'address': address,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

class Milestone {
  String phaseName;      // UI: "Day 1" or "Week 2"
  String taskName;       // UI: "Land Clearing"
  String verificationType; // "photo" (需要拍照) 或 "leader" (村长确认)
  String incentive;      // UI: "Incentive" (回报/奖励)
  String description;    // New: 任务详情描述

  Milestone({
    required this.phaseName,
    required this.taskName,
    required this.verificationType,
    required this.incentive,
    this.description = '',
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      phaseName: json['phase_name'] ?? '',
      taskName: json['task_name'] ?? '',
      verificationType: json['verification_type'] ?? 'leader',
      incentive: json['incentive'] ?? '',
      description: json['description'] ?? 'Perform the task according to village guidelines.',
    );
  }

  Map<String, dynamic> toJson() => {
    'phase_name': phaseName,
    'task_name': taskName,
    'verification_type': verificationType,
    'incentive': incentive,
    'description': description,
  };
}