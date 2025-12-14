// lib/View/LeaderUserInterface/project_details_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewModel/ProjectDetailsViewModel/project_details_view_model.dart';
import '../../models/ProjectRepository/project_model.dart';

class ProjectDetailsPage extends StatefulWidget {
  final Project project;

  const ProjectDetailsPage({super.key, required this.project});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<ProjectDetailsViewModel>(context, listen: false);
      if (widget.project.id != null) {
        viewModel.listenToProject(widget.project.id!);
      } else {
        viewModel.setProject(widget.project);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.project.title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<ProjectDetailsViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading && viewModel.project == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final project = viewModel.project ?? widget.project;
          return _buildProjectContent(context, viewModel, project);
        },
      ),
    );
  }

  Widget _buildProjectContent(BuildContext context, ProjectDetailsViewModel viewModel, Project project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Active",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Start Project Banner (IF NOT STARTED)
          if (!viewModel.isProjectStarted)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.shade100, width: 2),
              ),
              child: Column(
                children: [
                  const Icon(Icons.rocket_launch, size: 40, color: Colors.purple),
                  const SizedBox(height: 12),
                  const Text(
                    "Project Not Started",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purple),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Participants cannot submit work until you unlock Phase 1.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Start Project Now", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (project.id != null) {
                          await viewModel.startProject(project.id!);
                          messenger.showSnackBar(
                            const SnackBar(content: Text("Project Started! Phase 1 Unlocked."), backgroundColor: Colors.green),
                          );
                        }
                      },
                    ),
                  )
                ],
              ),
            ),

          // 3. Milestone Checklist
          _buildMilestoneChecklist(viewModel, project),
          const SizedBox(height: 32),

          // 4. Live KPIs
          _buildLiveKPIs(viewModel, project),
          const SizedBox(height: 32),

          // 5. Actions
          _buildProjectActions(viewModel, project),
        ],
      ),
    );
  }

  Widget _buildMilestoneChecklist(ProjectDetailsViewModel viewModel, Project project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Milestone Checklist",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...project.milestones.asMap().entries.map((entry) {
          final index = entry.key;
          final milestone = entry.value;
          return _buildMilestoneTile(viewModel, project, index, milestone);
        }),
      ],
    );
  }

  Widget _buildMilestoneTile(
      ProjectDetailsViewModel viewModel,
      Project project,
      int index,
      Milestone milestone,
      ) {
    IconData icon;
    Color iconColor;
    bool isEnabled;

    if (milestone.isCompleted) {
      icon = Icons.check_circle;
      iconColor = Colors.green;
      isEnabled = false;
    } else if (milestone.isOpen) {
      icon = Icons.radio_button_unchecked;
      iconColor = Colors.blue;
      isEnabled = true;
    } else {
      icon = Icons.radio_button_unchecked;
      iconColor = Colors.grey.shade400;
      isEnabled = false;
    }

    int submissionCount = milestone.submissions.length;
    bool hasPending = milestone.hasPendingReviews;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPending ? Colors.orange : Colors.grey.shade200,
          width: hasPending ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: isEnabled
                    ? () {
                  if (milestone.canBeCompleted) {
                    _showCompleteMilestoneDialog(viewModel, project.id!, index);
                  } else {
                    String message = "Cannot complete milestone: ";
                    if (milestone.submissions.isEmpty) {
                      message += "No submissions received yet.";
                    } else {
                      int pendingCount = milestone.pendingSubmissionsCount;
                      message += "$pendingCount submission(s) still pending review.";
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message), backgroundColor: Colors.orange),
                    );
                  }
                }
                    : null,
                child: Icon(
                  icon,
                  color: isEnabled ? iconColor : Colors.grey.shade400,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.taskName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      milestone.phaseName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (milestone.isOpen || milestone.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasPending ? Colors.orange.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$submissionCount submission${submissionCount != 1 ? 's' : ''}",
                    style: TextStyle(
                      fontSize: 11,
                      color: hasPending ? Colors.orange.shade700 : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (milestone.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              milestone.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            "Incentive: ${milestone.incentive}",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (milestone.isOpen || milestone.isCompleted) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showSubmissionsDialog(viewModel, project, index, milestone),
              icon: const Icon(Icons.rate_review, size: 16),
              label: Text(hasPending
                  ? "Review (${milestone.pendingSubmissionsCount} pending)"
                  : "View Submissions ($submissionCount)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasPending ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- KPI & Actions Sections ---

  Widget _buildLiveKPIs(ProjectDetailsViewModel viewModel, Project project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Live KPIs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildKPICard(
          "Milestone Progress",
          "${viewModel.milestoneProgress.toStringAsFixed(0)}%",
          "${project.milestones.where((m) => m.isCompleted).length} of ${project.milestones.length} completed",
          viewModel.milestoneProgress / 100,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildKPICard(
          "Youth Participation",
          "${viewModel.youthParticipation.toStringAsFixed(0)}%",
          "${project.activeParticipants.length} active participants",
          viewModel.youthParticipation / 100,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, String subtitle, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectActions(ProjectDetailsViewModel viewModel, Project project) {
    bool isCompleted = viewModel.isProjectCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Project Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isCompleted
                ? () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generate Final Impact - Coming Soon")));
            }
                : null,
            icon: const Icon(Icons.assessment),
            label: const Text("Generate Final Impact"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? const Color(0xFF2E7D32) : Colors.grey.shade300,
              foregroundColor: isCompleted ? Colors.white : Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isCompleted
                ? () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recommend Next Project - Coming Soon")));
            }
                : null,
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text("Recommend Next Project"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? const Color(0xFF2E7D32) : Colors.grey.shade300,
              foregroundColor: isCompleted ? Colors.white : Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  // --- Dialogs ---

  void _showCompleteMilestoneDialog(ProjectDetailsViewModel viewModel, String projectId, int milestoneIndex) {
    final milestone = viewModel.project?.milestones[milestoneIndex];
    if (milestone == null) return;
    // Capture messenger here
    final messenger = ScaffoldMessenger.of(context);

    if (!milestone.canBeCompleted) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Cannot complete milestone: Pending submissions exist."), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Complete Milestone?"),
        content: const Text("This will mark the milestone as completed and unlock the next phase."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await viewModel.completeMilestone(projectId, milestoneIndex);
              messenger.showSnackBar(const SnackBar(content: Text("Milestone completed!"), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Complete"),
          ),
        ],
      ),
    );
  }

  void _showSubmissionsDialog(ProjectDetailsViewModel viewModel, Project project, int milestoneIndex, Milestone milestone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Submissions Review", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: milestone.submissions.map((submission) {
                  return _buildSubmissionCard(viewModel, project.id!, milestoneIndex, submission);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(ProjectDetailsViewModel viewModel, String projectId, int milestoneIndex, MilestoneSubmission submission) {
    Color statusColor;
    IconData statusIcon;

    switch (submission.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: submission.status == 'pending' ? Colors.orange : Colors.grey.shade200,
          width: submission.status == 'pending' ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: statusColor.withOpacity(0.2), child: Icon(statusIcon, color: statusColor, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(submission.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(submission.status.toUpperCase(), style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text("RM ${submission.expenseClaimed}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text("Photo Proof Placeholder", style: TextStyle(color: Colors.grey))),
          ),
          if (submission.rejectionReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("Reason: ${submission.rejectionReason}", style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            ),
          if (submission.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showRejectDialog(viewModel, projectId, milestoneIndex, submission.userId),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Reject"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showApproveDialog(viewModel, projectId, milestoneIndex, submission.userId),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text("Approve"),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showApproveDialog(ProjectDetailsViewModel viewModel, String projectId, int milestoneIndex, String userId) {
    final commentController = TextEditingController();
    // CAPTURE MESSENGER CONTEXT HERE (Parent of dialog)
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Approve Submission"),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(hintText: "Optional comment...", border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // 1. Close Dialog
              Navigator.pop(ctx);

              // 2. Call VM (Optimistic Update)
              await viewModel.approveSubmission(projectId, milestoneIndex, userId, comment: commentController.text);

              // 3. Show SnackBar using captured messenger
              messenger.showSnackBar(const SnackBar(content: Text("Submission approved!"), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Approve"),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(ProjectDetailsViewModel viewModel, String projectId, int milestoneIndex, String userId) {
    final reasonController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Submission"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Enter rejection reason...", border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              Navigator.pop(ctx);
              await viewModel.rejectSubmission(projectId, milestoneIndex, userId, reasonController.text);
              messenger.showSnackBar(const SnackBar(content: Text("Submission rejected"), backgroundColor: Colors.red));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }
}