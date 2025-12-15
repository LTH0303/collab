part of 'project_model.dart';

/// Base state for a milestone submission.
abstract class SubmissionState {
  final MilestoneSubmission submission;
  SubmissionState(this.submission);

  bool get isPending => false;
  bool get isApproved => false;
  bool get isRejected => false;
  bool get isMissed => false;
}

class PendingState extends SubmissionState {
  PendingState(super.submission);
  @override
  bool get isPending => true;
}

class ApprovedState extends SubmissionState {
  ApprovedState(super.submission);
  @override
  bool get isApproved => true;
}

class RejectedState extends SubmissionState {
  RejectedState(super.submission);
  @override
  bool get isRejected => true;
}

class MissedState extends SubmissionState {
  MissedState(super.submission);
  @override
  bool get isMissed => true;
}

