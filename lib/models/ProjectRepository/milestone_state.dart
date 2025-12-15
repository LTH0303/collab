part of 'project_model.dart';

/// Base state for a milestone.
abstract class MilestoneState {
  final Milestone milestone;
  MilestoneState(this.milestone);

  bool get isOpen => false;
  bool get isLocked => false;
  bool get isCompleted => false;

  bool get hasPendingReviews =>
      milestone.submissions.any((s) => s.state.isPending);

  bool get hasApprovedSubmissions =>
      milestone.submissions.any((s) => s.state.isApproved);

  bool get canBeCompleted {
    if (milestone.submissions.isEmpty) return false;
    if (milestone.submissions.any((s) => s.state.isPending)) return false;
    if (milestone.submissions.any((s) => s.state.isRejected)) return false;
    return milestone.submissions
        .every((s) => s.state.isApproved || s.state.isMissed);
  }

  bool get isDueDatePassed {
    if (milestone.submissionDueDate == null) return false;
    return DateTime.now().isAfter(milestone.submissionDueDate!);
  }

  int get rejectedSubmissionsCount =>
      milestone.submissions.where((s) => s.state.isRejected).length;

  int get pendingSubmissionsCount =>
      milestone.submissions.where((s) => s.state.isPending).length;

  double get totalApprovedExpenses {
    return milestone.submissions
        .where((s) => s.state.isApproved)
        .fold(0.0, (sum, s) => sum + (double.tryParse(s.expenseClaimed) ?? 0));
  }
}

class LockedState extends MilestoneState {
  LockedState(super.milestone);
  @override
  bool get isLocked => true;
}

class OpenState extends MilestoneState {
  OpenState(super.milestone);
  @override
  bool get isOpen => true;
}

class CompletedState extends MilestoneState {
  CompletedState(super.milestone);
  @override
  bool get isCompleted => true;
}

