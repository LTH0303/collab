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

class MilestoneSubmission {
  String userId;
  String userName;
  String expenseClaimed;
  String proofImageUrl;
  String status; // 'pending', 'approved', 'rejected', 'missed'
  String? rejectionReason;
  DateTime submittedAt;

  MilestoneSubmission({
    required this.userId,
    required this.userName,
    required this.expenseClaimed,
    required this.proofImageUrl,
    this.status = 'pending',
    this.rejectionReason,
    required this.submittedAt,
  });

  factory MilestoneSubmission.fromJson(Map<String, dynamic> json) {
    return MilestoneSubmission(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'Unknown',
      expenseClaimed: json['expense_claimed']?.toString() ?? '0',
      proofImageUrl: json['proof_image_url'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_name': userName,
    'expense_claimed': expenseClaimed,
    'proof_image_url': proofImageUrl,
    'status': status,
    'rejection_reason': rejectionReason,
    'submitted_at': submittedAt.toIso8601String(),
  };
}

class Milestone {
  String phaseName;
  String taskName;
  String verificationType;
  String incentive;
  String description;
  String allocatedBudget;

  String status; // 'locked', 'open', 'completed' (Note: 'pending_review' logic now depends on submissions)
  List<MilestoneSubmission> submissions; // List of submissions from different youths

  Milestone({
    required this.phaseName,
    required this.taskName,
    required this.verificationType,
    required this.incentive,
    this.description = '',
    this.allocatedBudget = '0',
    this.status = 'locked',
    this.submissions = const [],
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      phaseName: json['phase_name'] ?? '',
      taskName: json['task_name'] ?? '',
      verificationType: json['verification_type'] ?? 'leader',
      incentive: json['incentive'] ?? '',
      description: json['description'] ?? 'Perform the task according to village guidelines.',
      allocatedBudget: json['allocated_budget']?.toString() ?? '0',
      status: json['status'] ?? 'locked',
      submissions: (json['submissions'] as List? ?? [])
          .map((s) => MilestoneSubmission.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'phase_name': phaseName,
    'task_name': taskName,
    'verification_type': verificationType,
    'incentive': incentive,
    'description': description,
    'allocated_budget': allocatedBudget,
    'status': status,
    'submissions': submissions.map((s) => s.toJson()).toList(),
  };

  // Helper properties
  bool get isOpen => status == 'open';
  bool get isLocked => status == 'locked';
  bool get isCompleted => status == 'completed'; // Whole phase marked complete by leader

  bool get hasPendingReviews => submissions.any((s) => s.status == 'pending');
  bool get hasApprovedSubmissions => submissions.any((s) => s.status == 'approved');

  // Check if milestone can be marked as completed
  bool get canBeCompleted {
    if (submissions.isEmpty) return false;
    return submissions.every((s) => s.status != 'pending');
  }

  // Get count of pending submissions
  int get pendingSubmissionsCount => submissions.where((s) => s.status == 'pending').length;

  // Helper to calculate total claimed from approved submissions
  double get totalApprovedExpenses {
    return submissions
        .where((s) => s.status == 'approved')
        .fold(0.0, (sum, s) => sum + (double.tryParse(s.expenseClaimed) ?? 0));
  }
}