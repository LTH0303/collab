// lib/View/LeaderUserInterface/project_details_page.dart

import 'dart:convert'; // Added for Base64 Decoding
import 'dart:typed_data'; // Added for Uint8List
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ViewModel/ProjectDetailsViewModel/project_details_view_model.dart';
import '../../models/ProjectRepository/project_model.dart';
import 'hired_youth_list_view.dart';
import 'completed_project_page.dart';
import 'leader_main_layout.dart';

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
        // Auto-check expired submissions for open milestone when page loads
        _autoCheckExpiredSubmissions(viewModel, widget.project);
      } else {
        viewModel.setProject(widget.project);
      }
    });
  }

  // Auto-check expired submissions for the current open milestone
  // This should be called whenever we need to check (page load, viewing submissions, etc.)
  void _autoCheckExpiredSubmissions(ProjectDetailsViewModel viewModel, Project project) async {
    if (project.id == null) return;

    print("🔍 _autoCheckExpiredSubmissions called for project ${project.id}");

    // Find the first (and only) open milestone
    for (int i = 0; i < project.milestones.length; i++) {
      final milestone = project.milestones[i];
      if (milestone.isOpen && milestone.submissionDueDate != null) {
        // Always check if due date has passed using UTC comparison
        final nowUtc = DateTime.now().toUtc();
        final dueDateUtc = milestone.submissionDueDate!.toUtc();

        print("   Milestone $i: Due date (UTC) = $dueDateUtc, Now (UTC) = $nowUtc");

        if (nowUtc.isAfter(dueDateUtc)) {
          print("🔄 Due date PASSED - Auto-checking expired submissions for milestone $i");
          await viewModel.checkExpiredSubmissions(project.id!, i);
          break; // Only one milestone can be open at a time
        } else {
          print("   ⏰ Due date NOT passed yet (${dueDateUtc.difference(nowUtc).inMinutes} minutes remaining)");
        }
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: Colors.black),
            tooltip: "View Hired Team",
            onPressed: () {
              if (widget.project.id != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HiredYouthListView(
                      projectId: widget.project.id!,
                      projectTitle: widget.project.title,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cannot view team: Project ID missing")),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<ProjectDetailsViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading && viewModel.project == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final project = viewModel.project ?? widget.project;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: _buildProjectContent(context, viewModel, project),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectContent(BuildContext context, ProjectDetailsViewModel viewModel, Project project) {
    bool isActive = project.status == 'active';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? "Active" : "Completed",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),

          // --- Expandable Project Overview ---
          _buildExpandableOverview(project, isActive),
          const SizedBox(height: 24),

          // 2. Start Project Banner (IF NOT STARTED & NOT COMPLETED)
          if (!viewModel.isProjectStarted && isActive)
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

    // Count only actual submissions (exclude "missed" ones that are auto-generated)
    int submissionCount = milestone.submissions.where((s) => s.status != 'missed').length;
    int expectedCount = project.activeParticipants.length;
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
                    ? () async {
                  // First, check and mark expired submissions if due date has passed
                  if (project.id != null && milestone.isOpen) {
                    await viewModel.checkExpiredSubmissions(project.id!, index);
                    // Refresh project data after checking
                    final updatedProject = viewModel.project ?? project;
                    final updatedMilestone = updatedProject.milestones[index];

                    // Check if all participants have submitted (approved or missed)
                    Set<String> submittedUserIds = updatedMilestone.submissions.map((s) => s.userId).toSet();
                    List<String> missingParticipants = updatedProject.activeParticipants
                        .where((pid) => !submittedUserIds.contains(pid))
                        .toList();

                    // All participants must have a submission (approved or missed)
                    // No pending or rejected submissions allowed
                    if (missingParticipants.isEmpty &&
                        updatedMilestone.pendingSubmissionsCount == 0 &&
                        updatedMilestone.rejectedSubmissionsCount == 0 &&
                        updatedMilestone.submissions.isNotEmpty) {
                      _showCompleteMilestoneDialog(viewModel, project.id!, index);
                    } else {
                      String message = "Cannot complete milestone: ";
                      if (missingParticipants.isNotEmpty) {
                        message += "Not all participants have submitted. ${missingParticipants.length} participant(s) missing.";
                      } else if (updatedMilestone.submissions.isEmpty) {
                        message += "No submissions received yet.";
                      } else if (updatedMilestone.pendingSubmissionsCount > 0) {
                        message += "${updatedMilestone.pendingSubmissionsCount} submission(s) still pending review.";
                      } else if (updatedMilestone.rejectedSubmissionsCount > 0) {
                        message += "${updatedMilestone.rejectedSubmissionsCount} submission(s) rejected and need re-upload.";
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message), backgroundColor: Colors.orange),
                      );
                    }
                  }
                }
                    : null,
                child: Icon(
                  icon,
                  color: milestone.isCompleted
                      ? iconColor
                      : (isEnabled ? iconColor : Colors.grey.shade400),
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
          // Due Date Section
          if (milestone.isOpen) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    milestone.submissionDueDate != null
                        ? "Due: ${_formatDate(milestone.submissionDueDate!)} ${milestone.isDueDatePassed ? '(OVERDUE)' : ''}"
                        : "No due date set",
                    style: TextStyle(
                      fontSize: 12,
                      color: milestone.submissionDueDate != null && milestone.isDueDatePassed
                          ? Colors.red
                          : Colors.grey.shade600,
                      fontWeight: milestone.submissionDueDate != null && milestone.isDueDatePassed
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showSetDueDateDialog(viewModel, project.id!, index, milestone),
                  icon: const Icon(Icons.edit, size: 14),
                  label: Text(milestone.submissionDueDate != null ? "Change" : "Set Due Date"),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
          if (milestone.isOpen || milestone.isCompleted) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                if (project.id != null) {
                  // CRITICAL: Always check expired submissions before showing dialog
                  // This ensures missing submissions are created if due date has passed
                  print("🔍 View Submissions clicked - checking expired submissions first");
                  await viewModel.checkExpiredSubmissions(project.id!, index);
                  // Get fresh project data after check
                  final updatedProject = viewModel.project ?? project;
                  if (updatedProject.milestones.length > index) {
                    _showSubmissionsDialog(viewModel, updatedProject, index, updatedProject.milestones[index]);
                  } else {
                    _showSubmissionsDialog(viewModel, project, index, milestone);
                  }
                } else {
                  _showSubmissionsDialog(viewModel, project, index, milestone);
                }
              },
              icon: const Icon(Icons.rate_review, size: 16),
              label: Text(hasPending
                  ? "Review (${milestone.pendingSubmissionsCount} pending)"
                  : "View Submissions ($submissionCount/$expectedCount)"),
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
    final bool allMilestonesDone = viewModel.isProjectCompleted;
    final bool isStatusCompleted = project.status == 'completed';
    final bool canGenerateImpact = allMilestonesDone && !isStatusCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Project Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Only show "Generate Final Impact" button when all milestones are done but project is still active
        if (canGenerateImpact)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (project.id == null) return;
                await viewModel.finalizeProject(project.id!);

                // Refresh project data after finalizing
                final updatedProject = viewModel.project ?? project;

                if (mounted) {
                  // Navigate back to Projects section and switch to Completed tab
                  // Pop back to the main layout (Projects tab)
                  Navigator.popUntil(context, (route) {
                    // Check if we're back at the main layout
                    return route.isFirst || route.settings.name == '/leader';
                  });

                  // Navigate to leader main layout with Projects tab active and Completed sub-tab
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeaderMainLayoutWithProjectsTab(
                        initialSubTab: 2, // 2 = Completed tab
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.assessment),
              label: const Text("Generate Final Impact"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

        // "Recommend Next Project" button - always visible but disabled when not completed
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isStatusCompleted
                ? () {
              // Navigate to AI Planner with project outcomes as resources
              // Defensive check: ensure actualOutcomes and expectedOutcomes exist
              final actualOutcomes = project.actualOutcomes ?? <String>[];
              final expectedOutcomes = project.expectedOutcomes ?? <String>[];
              final outcomes = actualOutcomes.isNotEmpty
                  ? actualOutcomes
                  : expectedOutcomes;
              final resources = outcomes.isNotEmpty
                  ? outcomes.join(', ')
                  : "Project: ${project.title}, Skills: ${project.skills.join(', ')}";

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LeaderMainLayoutWithData(
                    initialTab: 0, // AI Planner tab
                    prefillResources: resources,
                    prefillBudget: project.totalBudget,
                  ),
                ),
              );
            }
                : null,
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text("Recommend Next Project"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isStatusCompleted ? const Color(0xFF2E7D32) : Colors.grey.shade300,
              foregroundColor: isStatusCompleted ? Colors.white : Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showCompleteMilestoneDialog(ProjectDetailsViewModel viewModel, String projectId, int milestoneIndex) {
    final milestone = viewModel.project?.milestones[milestoneIndex];
    if (milestone == null) return;
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

  void _showSubmissionsDialog(ProjectDetailsViewModel viewModel, Project project, int milestoneIndex, Milestone milestone) async {
    // CRITICAL: Ensure ALL participants are shown, even if they don't have submissions in Firestore
    // This handles cases where old completed milestones were completed before the auto-missing feature was added
    final allSubmissions = List<MilestoneSubmission>.from(milestone.submissions);
    final expectedParticipants = project.activeParticipants;
    final submittedUserIds = allSubmissions.map((s) => s.userId).toSet();

    print("📋 _showSubmissionsDialog: Expected ${expectedParticipants.length} participants, Found ${allSubmissions.length} submissions");
    print("   Expected participants: $expectedParticipants");
    print("   Submitted user IDs: $submittedUserIds");

    // For each participant who doesn't have a submission, create a placeholder "missed" submission for display
    for (String participantId in expectedParticipants) {
      if (!submittedUserIds.contains(participantId)) {
        print("   ➕ Creating placeholder for missing participant: $participantId");
        // Fetch the actual user name from Firestore
        String userName = "Unknown Participant";
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(participantId).get();
          if (userDoc.exists) {
            userName = userDoc.data()?['name'] ?? "Unknown Participant";
            print("   ✅ Fetched name: $userName");
          } else {
            print("   ⚠️ User document not found for $participantId");
          }
        } catch (e) {
          print("   ❌ Error fetching user name for display: $e");
        }

        // Create a placeholder "missed" submission for display only (not saved to Firestore)
        allSubmissions.add(MilestoneSubmission(
          userId: participantId,
          userName: userName,
          expenseClaimed: "0",
          proofImageUrl: "",
          status: "missed",
          rejectionReason: milestone.isCompleted
              ? "System: No submission recorded (historical data)"
              : "System: No submission before due date",
          submittedAt: DateTime.now(),
        ));
      }
    }

    print("📊 Final submission count: ${allSubmissions.length} (should be ${expectedParticipants.length})");

    // Sort submissions: approved first, then by participant order
    allSubmissions.sort((a, b) {
      // Approved submissions first
      bool aIsApproved = a.status == 'approved';
      bool bIsApproved = b.status == 'approved';
      if (aIsApproved && !bIsApproved) return -1;
      if (!aIsApproved && bIsApproved) return 1;

      // Then sort by participant order
      int indexA = expectedParticipants.indexOf(a.userId);
      int indexB = expectedParticipants.indexOf(b.userId);
      if (indexA == -1) indexA = 999; // Put unknown participants at the end
      if (indexB == -1) indexB = 999;
      return indexA.compareTo(indexB);
    });

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Submissions Review", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (milestone.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Completed",
                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Summary showing total participants
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: allSubmissions.length >= expectedParticipants.length
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: allSubmissions.length >= expectedParticipants.length
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    allSubmissions.length >= expectedParticipants.length
                        ? Icons.check_circle
                        : Icons.warning,
                    size: 16,
                    color: allSubmissions.length >= expectedParticipants.length
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Showing ${allSubmissions.length} / ${expectedParticipants.length} participants",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: allSubmissions.length >= expectedParticipants.length
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: allSubmissions.isEmpty
                  ? const Center(child: Text("No submissions yet"))
                  : ListView(
                children: allSubmissions.map((submission) {
                  return _buildSubmissionCard(viewModel, project.id!, milestoneIndex, submission, milestone.isCompleted, milestone);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(ProjectDetailsViewModel viewModel, String projectId, int milestoneIndex, MilestoneSubmission submission, bool isMilestoneCompleted, Milestone milestone) {
    Color statusColor;
    IconData statusIcon;
    Color expenseColor = Colors.green; // Default for expenses

    // Check if due date has passed
    final bool isDueDatePassed = milestone.submissionDueDate != null &&
        DateTime.now().toUtc().isAfter(milestone.submissionDueDate!.toUtc());

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
        expenseColor = Colors.red; // Rejected expenses are red
        break;
      case 'missed':
      // For completed milestones: always red (definitely missed)
      // For active milestones: red if due date passed, grey if not yet (waiting for submission)
        if (isMilestoneCompleted) {
          statusColor = Colors.red; // Completed milestone = definitely missed
          expenseColor = Colors.red;
        } else {
          statusColor = isDueDatePassed ? Colors.red : Colors.grey; // Active: red if overdue, grey if waiting
          expenseColor = isDueDatePassed ? Colors.red : Colors.grey;
        }
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    final bool hasImage = submission.proofImageUrl.isNotEmpty &&
        submission.proofImageUrl != "https://mock.url/photo.jpg" &&
        submission.proofImageUrl != "https://via.placeholder.com/150";

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
              Text(
                "RM ${submission.expenseClaimed}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: expenseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- CHANGED: IMAGE DISPLAY LOGIC TO SUPPORT BASE64 ---
          GestureDetector(
            onTap: hasImage ? () => _showFullImage(context, submission.proofImageUrl) : null,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: hasImage
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageWidget(submission.proofImageUrl),
              )
                  : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, color: Colors.grey),
                    Text("No Photo Uploaded", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          // ----------------------------------------------------

          // Show rejection reason for:
          // 1. Rejected submissions
          // 2. Missed submissions that were previously rejected (have rejectionReason)
          if (submission.rejectionReason != null &&
              (submission.status == 'rejected' ||
                  (submission.status == 'missed' && submission.rejectionReason!.contains("Rejected"))))
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Reason: ${submission.rejectionReason}",
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
          // Show action buttons only if milestone is not completed and submission is pending
          if (!isMilestoneCompleted && submission.status == 'pending') ...[
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

  // --- NEW HELPER: DECIDE WHETHER TO USE NETWORK OR MEMORY (BASE64) ---
  Widget _buildImageWidget(String imageString) {
    if (imageString.startsWith('http')) {
      return Image.network(
        imageString,
        fit: BoxFit.cover,
        errorBuilder: (ctx, _, __) => const Center(child: Icon(Icons.broken_image)),
      );
    } else {
      try {
        Uint8List decodedBytes = base64Decode(imageString);
        return Image.memory(
          decodedBytes,
          fit: BoxFit.cover,
          errorBuilder: (ctx, _, __) => const Center(child: Icon(Icons.broken_image)),
        );
      } catch (e) {
        return const Center(child: Text("Invalid Image Data"));
      }
    }
  }

  void _showFullImage(BuildContext context, String imageString) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                // Re-use helper for full screen logic
                _buildImageWidget(imageString),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
// ... rest of the file (approve/reject dialogs) remains same ...

  void _showApproveDialog(ProjectDetailsViewModel viewModel, String projectId, int milestoneIndex, String userId) {
    final commentController = TextEditingController();
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
              Navigator.pop(ctx);
              await viewModel.approveSubmission(projectId, milestoneIndex, userId, comment: commentController.text);
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

  Widget _buildExpandableOverview(Project project, bool isActive) {
    return _ExpandableOverviewCard(project: project, isActive: isActive);
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showSetDueDateDialog(ProjectDetailsViewModel viewModel, String projectId, int milestoneIndex, Milestone milestone) {
    DateTime initialDate = milestone.submissionDueDate ?? DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) {
        return _DueDatePickerDialog(
          initialDate: initialDate,
          onDateSelected: (selectedDate) async {
            Navigator.pop(ctx);
            await viewModel.setMilestoneDueDate(projectId, milestoneIndex, selectedDate);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Due date set to ${_formatDate(selectedDate)}"),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }
}

class _ExpandableOverviewCard extends StatefulWidget {
  final Project project;
  final bool isActive;

  const _ExpandableOverviewCard({
    required this.project,
    required this.isActive,
  });

  @override
  State<_ExpandableOverviewCard> createState() => _ExpandableOverviewCardState();
}

class _ExpandableOverviewCardState extends State<_ExpandableOverviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Header (always visible)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Project Overview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewItem("Timeline", widget.project.timeline),
                  const SizedBox(height: 16),
                  _buildOverviewItem("Total Budget", "RM ${widget.project.totalBudget}"),
                  const SizedBox(height: 16),
                  // Required Skills - only for active projects, use bullet points
                  if (widget.isActive) ...[
                    _buildOverviewSectionTitle("Required Skills"),
                    const SizedBox(height: 8),
                    if (widget.project.skills.isEmpty)
                      Text("No specific skills listed.", style: TextStyle(color: Colors.grey.shade600, fontSize: 14))
                    else
                      ...widget.project.skills.map((skill) => Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ", style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(skill, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ),
                          ],
                        ),
                      )),
                    const SizedBox(height: 16),
                  ],
                  _buildOverviewItem("Youth Participants Needed", widget.project.participantRange),
                  const SizedBox(height: 16),
                  _buildOverviewItem("Starting Materials", widget.project.startingResources.join(", ")),
                  const SizedBox(height: 16),
                  _buildOverviewItem("Address", widget.project.address, icon: Icons.location_on),
                  const SizedBox(height: 16),
                  _buildOverviewSectionTitle("Project Description"),
                  const SizedBox(height: 8),
                  Text(
                    widget.project.description.isNotEmpty ? widget.project.description : "No description available.",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
                  ),
                  // Expected Outcomes - only for active projects
                  if (widget.isActive) ...[
                    const SizedBox(height: 16),
                    _buildOverviewSectionTitle("Expected Outcomes"),
                    const SizedBox(height: 8),
                    if ((widget.project.expectedOutcomes ?? []).isEmpty)
                      Text(
                        "No expected outcomes defined yet.",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (widget.project.expectedOutcomes ?? [])
                              .map((outcome) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.radio_button_unchecked,
                                  size: 16,
                                  color: Color(0xFF4CAF50),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    outcome,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                              .toList(),
                        ),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
    );
  }
}

class _DueDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const _DueDatePickerDialog({
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<_DueDatePickerDialog> createState() => _DueDatePickerDialogState();
}

class _DueDatePickerDialogState extends State<_DueDatePickerDialog> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Set Submission Due Date"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Select the due date for all participants to submit their work:"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(selectedDate),
                );
                if (time != null) {
                  setState(() {
                    selectedDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              }
            },
            child: Text("Select: ${_formatDate(selectedDate)} ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onDateSelected(selectedDate);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
          child: const Text("Set Due Date"),
        ),
      ],
    );
  }
}