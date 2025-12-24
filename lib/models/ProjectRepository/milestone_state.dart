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

  // Check if all participants have submissions (approved or missed)
  bool canBeCompletedWithParticipants(List<String> activeParticipants) {
    if (activeParticipants.isEmpty) return false;

    // Check that all participants have a submission (approved or missed)
    Set<String> submittedUserIds = milestone.submissions.map((s) => s.userId).toSet();

    // All participants must have submitted
    for (String participantId in activeParticipants) {
      if (!submittedUserIds.contains(participantId)) {
        return false; // Missing submission from a participant
      }
    }

    // Check that all existing submissions are either approved or missed (no pending/rejected)
    if (milestone.submissions.any((s) => s.state.isPending)) return false;
    if (milestone.submissions.any((s) => s.state.isRejected)) return false;

    return true;
  }

  bool get isDueDatePassed {
    if (milestone.submissionDueDate == null) return false;
    // FIX: Compare both in UTC to avoid timezone issues
    // The due date from Firestore is stored as UTC (via toIso8601String())
    // DateTime.now() is local time, so we convert both to UTC for accurate comparison
    final nowUtc = DateTime.now().toUtc();
    final dueDateUtc = milestone.submissionDueDate!.toUtc();
    return nowUtc.isAfter(dueDateUtc);
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

