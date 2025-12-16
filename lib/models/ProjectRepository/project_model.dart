// lib/models/project_model.dart

part 'milestone_state.dart';
part 'submission_state.dart';

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
  int? initialPopulation; // Population at project start (for impact)
  int? currentPopulation; // Current population when project completed
  DateTime? completedAt; // When project was marked completed
  DateTime? createdAt; // When project was created

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
    this.initialPopulation,
    this.currentPopulation,
    this.completedAt,
    this.createdAt,
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
      initialPopulation: json['initial_population'],
      currentPopulation: json['current_population'],
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
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
      'initial_population': initialPopulation,
      'current_population': currentPopulation,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'milestones': milestones.map((m) => m.toJson()).toList(),
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

  SubmissionState get state {
    switch (status) {
      case 'approved':
        return ApprovedState(this);
      case 'rejected':
        return RejectedState(this);
      case 'missed':
        return MissedState(this);
      case 'pending':
      default:
        return PendingState(this);
    }
  }

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
  DateTime? submissionDueDate; // Due date for submissions (set by leader)

  MilestoneState get state {
    switch (status) {
      case 'open':
        return OpenState(this);
      case 'completed':
        return CompletedState(this);
      case 'locked':
      default:
        return LockedState(this);
    }
  }

  Milestone({
    required this.phaseName,
    required this.taskName,
    required this.verificationType,
    required this.incentive,
    this.description = '',
    this.allocatedBudget = '0',
    this.status = 'locked',
    this.submissions = const [],
    this.submissionDueDate,
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
      submissionDueDate: json['submission_due_date'] != null
          ? DateTime.parse(json['submission_due_date'])
          : null,
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
    'submission_due_date': submissionDueDate?.toIso8601String(),
  };

  // Helper properties
  bool get isOpen => state.isOpen;
  bool get isLocked => state.isLocked;
  bool get isCompleted => state.isCompleted; // Whole phase marked complete by leader

  bool get hasPendingReviews => state.hasPendingReviews;
  bool get hasApprovedSubmissions => state.hasApprovedSubmissions;

  // Check if milestone can be marked as completed
  bool get canBeCompleted => state.canBeCompleted;

  // Check if due date has passed
  bool get isDueDatePassed => state.isDueDatePassed;

  // Get count of rejected submissions
  int get rejectedSubmissionsCount => state.rejectedSubmissionsCount;

  // Get count of pending submissions
  int get pendingSubmissionsCount => state.pendingSubmissionsCount;

  // Helper to calculate total claimed from approved submissions
  double get totalApprovedExpenses => state.totalApprovedExpenses;
}