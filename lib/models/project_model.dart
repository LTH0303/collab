// lib/models/project_model.dart

class Project {
  String? id;
  String title;
  String description;
  String timeline;
  List<String> skills;
  String participantRange;
  List<Milestone> milestones;
  String status;
  List<String> startingResources;
  String address;
  String totalBudget;
  String? leaderId;
  List<String> activeParticipants; // List of User IDs

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
    this.totalBudget = '0',
    this.leaderId,
    this.activeParticipants = const [],
  });

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
      totalBudget: json['total_budget']?.toString() ?? '0',
      leaderId: json['leader_id'],
      activeParticipants: List<String>.from(json['active_participants'] ?? []),
      milestones: (json['milestones'] as List? ?? [])
          .map((m) => Milestone.fromJson(m))
          .toList(),
    );
  }

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
      'total_budget': totalBudget,
      'leader_id': leaderId,
      'active_participants': activeParticipants,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

class Milestone {
  String phaseName;
  String taskName;
  String verificationType;
  String incentive;
  String description;
  String allocatedBudget;

  // Submission & Review Fields
  String expenseClaimed;
  String? proofImageUrl; // URL for photo
  String status; // 'locked', 'open', 'pending_review', 'completed', 'rejected'
  String? rejectionReason;

  Milestone({
    required this.phaseName,
    required this.taskName,
    required this.verificationType,
    required this.incentive,
    this.description = '',
    this.allocatedBudget = '0',
    this.expenseClaimed = '0',
    this.proofImageUrl,
    this.status = 'locked',
    this.rejectionReason,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      phaseName: json['phase_name'] ?? '',
      taskName: json['task_name'] ?? '',
      verificationType: json['verification_type'] ?? 'leader',
      incentive: json['incentive'] ?? '',
      description: json['description'] ?? 'Perform the task according to village guidelines.',
      allocatedBudget: json['allocated_budget']?.toString() ?? '0',
      expenseClaimed: json['expense_claimed']?.toString() ?? '0',
      proofImageUrl: json['proof_image_url'],
      status: json['status'] ?? 'locked',
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() => {
    'phase_name': phaseName,
    'task_name': taskName,
    'verification_type': verificationType,
    'incentive': incentive,
    'description': description,
    'allocated_budget': allocatedBudget,
    'expense_claimed': expenseClaimed,
    'proof_image_url': proofImageUrl,
    'status': status,
    'rejection_reason': rejectionReason,
  };

  // Helper for UI
  bool get isCompleted => status == 'completed';
  bool get isPendingReview => status == 'pending_review';
  bool get isRejected => status == 'rejected';
  bool get isOpen => status == 'open';
  bool get isLocked => status == 'locked';
}