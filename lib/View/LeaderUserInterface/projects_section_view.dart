// lib/View/LeaderUserInterface/projects_section_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../ViewModel/PlannerViewModel/planner_view_model.dart';
import '../../ViewModel/ApplicationViewModel/application_view_model.dart';
import '../../models/ProjectRepository/project_model.dart';
import '../../models/ProjectRepository/application_model.dart';
import '../../models/DatabaseService/database_service.dart';
import 'applicant_profile_view.dart';
import 'hired_youth_list_view.dart';

class ProjectsSection extends StatefulWidget {
  const ProjectsSection({super.key});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PlannerViewModel>(context);

    if (viewModel.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(viewModel.error!),
          backgroundColor: Colors.red,
        ));
      });
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _buildSegmentButton("Draft", 0),
              _buildSegmentButton("Active", 1),
              _buildSegmentButton("Completed", 2),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: _buildContent(viewModel),
        ),
      ],
    );
  }

  Widget _buildContent(PlannerViewModel viewModel) {
    if (_selectedIndex == 0) {
      return _buildDraftsList(viewModel);
    } else if (_selectedIndex == 1) {
      return _buildActiveProjectsList();
    } else {
      return _buildCompletedProjectsList();
    }
  }

  Widget _buildSegmentButton(String text, int index) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF558B6E) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraftsList(PlannerViewModel viewModel) {
    if (viewModel.drafts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.edit_note, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("No drafts yet", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: viewModel.drafts.length,
      itemBuilder: (context, index) {
        return DraftInlineEditorCard(
          project: viewModel.drafts[index],
          onPublish: () => viewModel.publishDraft(index),
          onDelete: () => viewModel.removeDraft(index),
        );
      },
    );
  }

  Widget _buildActiveProjectsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<List<Project>>(
      stream: DatabaseService().getLeaderProjects(user.uid, 'active'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No active projects. Publish one!"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildActiveCard(context, snapshot.data![index]);
          },
        );
      },
    );
  }

  Widget _buildCompletedProjectsList() {
    return const Center(child: Text("No completed projects yet.", style: TextStyle(color: Colors.grey)));
  }

  Widget _buildActiveCard(BuildContext context, Project project) {
    bool hasPendingReview = project.milestones.any((m) => m.hasPendingReviews);
    bool isProjectStarted = project.milestones.isNotEmpty && (project.milestones[0].isOpen || project.milestones[0].isCompleted);

    return GestureDetector(
      onTap: () => _showActiveProjectDetails(context, project, isProjectStarted),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                    child: const Text("Active", style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                  if (hasPendingReview)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                      child: const Text("REVIEW NEEDED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  else if (!isProjectStarted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(8)),
                      child: const Text("NOT STARTED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(project.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 16, color: Colors.green),
                      Text(project.totalBudget, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(width: 16),
                      const Icon(Icons.flag, size: 16, color: Colors.orange),
                      Text("${project.milestones.length} Milestones"),
                    ],
                  ),
                ],
              ),
            ),
            // --- NEW LOCATION: Pending Applications show up here if they exist ---
            if (project.id != null)
              _buildPendingApplicationsSection(context, project.id!),
          ],
        ),
      ),
    );
  }

  void _showActiveProjectDetails(BuildContext context, Project project, bool isProjectStarted) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, color: Colors.grey[300])),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(project.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HiredYouthListView(
                            projectId: project.id!,
                            projectTitle: project.title,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.groups, color: Colors.blue, size: 28),
                    tooltip: "View Hired Team",
                  )
                ],
              ),

              const SizedBox(height: 20),

              // REMOVED PENDING APPLICATIONS SECTION FROM HERE (MOVED TO CARD)

              if (!isProjectStarted)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: Column(
                    children: [
                      const Text("Project Not Started", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                      const Text("Participants cannot submit work until you unlock Phase 1.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Start Project Now"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await DatabaseService().startProject(project.id!);
                            if (context.mounted) {
                              Navigator.pop(context);
                              messenger.showSnackBar(const SnackBar(content: Text("Project Started! Phase 1 Unlocked.")));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              messenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                            }
                          }
                        },
                      )
                    ],
                  ),
                ),

              const Text("Milestones Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: project.milestones.asMap().entries.map((entry) {
                    var index = entry.key;
                    var m = entry.value;

                    // UPDATED LOGIC:
                    // Can unlock next IF:
                    // 1. Current phase has AT LEAST ONE approved submission (OR is already marked completed)
                    // 2. Next phase exists and is locked
                    bool isNextLocked = index + 1 < project.milestones.length && project.milestones[index+1].isLocked;
                    bool canUnlockNext = (m.hasApprovedSubmissions || m.isCompleted) && isNextLocked;

                    return Column(
                      children: [
                        _buildLeaderMilestoneReviewTile(context, project, index, m),
                        if (canUnlockNext)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton.icon(
                              onPressed: () => _showUnlockConfirmation(context, project, index),
                              icon: const Icon(Icons.lock_open, size: 16),
                              label: const Text("Unlock Next Phase"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 36),
                              ),
                            ),
                          )
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnlockConfirmation(BuildContext context, Project project, int index) {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Unlock Next Phase?"),
        content: const Text("Are you sure you want to proceed? This will allow all participants to start working on the next milestone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                await DatabaseService().unlockNextPhase(project.id!, index);
                messenger.showSnackBar(const SnackBar(content: Text("Next Phase Unlocked!"), backgroundColor: Colors.green));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Confirm & Unlock"),
          )
        ],
      ),
    );
  }

  Widget _buildLeaderMilestoneReviewTile(BuildContext context, Project project, int index, Milestone m) {
    Color color = Colors.grey;
    IconData icon = Icons.circle_outlined;
    bool needsReview = m.hasPendingReviews;
    int pendingCount = m.submissions.where((s) => s.status == 'pending').length;

    if (m.isCompleted) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (needsReview) {
      color = Colors.orange;
      icon = Icons.hourglass_full;
    } else if (m.isOpen) {
      color = Colors.blue;
      icon = Icons.play_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: needsReview ? BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(icon, color: color),
        title: Text(m.taskName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Allocated: RM ${m.allocatedBudget}"),
            if (m.hasApprovedSubmissions)
              Text("Approved: RM ${m.totalApprovedExpenses}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            if (needsReview)
              Text("$pendingCount Submission(s) Pending", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
            if (m.isOpen && !needsReview)
              const Text("IN PROGRESS", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold))
          ],
        ),
        trailing: needsReview
            ? ElevatedButton(
          onPressed: () => _showReviewListDialog(context, project, index, m),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, textStyle: const TextStyle(fontSize: 12)),
          child: Text("Review ($pendingCount)"),
        )
            : null,
      ),
    );
  }

  void _showReviewListDialog(BuildContext context, Project project, int index, Milestone m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Pending Submissions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: m.submissions.where((s) => s.status == 'pending').map((sub) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(radius: 16, backgroundColor: Colors.blue, child: Icon(Icons.person, size: 16, color: Colors.white)),
                              const SizedBox(width: 8),
                              Text(sub.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text("RM ${sub.expenseClaimed}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 120,
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: const Text("Photo Proof Mockup", style: TextStyle(color: Colors.grey)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => _handleSubmissionAction(context, project.id!, index, sub.userId, false),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text("Reject"),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () => _handleSubmissionAction(context, project.id!, index, sub.userId, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                child: const Text("Approve"),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmissionAction(BuildContext context, String projectId, int milestoneIndex, String userId, bool approve) {
    final reasonController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    if (!approve) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Reject Submission"),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(hintText: "Enter reason..."),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                Navigator.pop(context);

                await DatabaseService().reviewMilestoneSubmission(projectId, milestoneIndex, userId, false, reasonController.text);
                messenger.showSnackBar(const SnackBar(content: Text("Submission Rejected."), backgroundColor: Colors.red));
              },
              child: const Text("Confirm Reject"),
            )
          ],
        ),
      );
    } else {
      Navigator.pop(context);

      DatabaseService().reviewMilestoneSubmission(projectId, milestoneIndex, userId, true, null)
          .then((_) => messenger.showSnackBar(const SnackBar(content: Text("Submission Approved!"), backgroundColor: Colors.green)))
          .catchError((e) => messenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)));
    }
  }

  // --- REFACTORED: Smart Section ---
  Widget _buildPendingApplicationsSection(BuildContext context, String projectId) {
    final appViewModel = Provider.of<ApplicationViewModel>(context, listen: false);

    return StreamBuilder<List<Application>>(
      stream: appViewModel.getProjectApplications(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }

        // Hide completely if no pending applications
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const Text("Pending Applications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final app = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.orange[50], // Slight tint to make it pop
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(app.applicantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text("Applied: ${app.appliedAt.toString().substring(0,10)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => appViewModel.rejectApplicant(app)),
                                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => appViewModel.approveApplicant(app)),
                                  ],
                                )
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ApplicantProfileView(application: app),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_search, size: 14),
                                label: const Text("View Profile", style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ... DraftInlineEditorCard (Same as before)
class DraftInlineEditorCard extends StatefulWidget {
  final Project project;
  final VoidCallback onPublish;
  final VoidCallback onDelete;

  const DraftInlineEditorCard({super.key, required this.project, required this.onPublish, required this.onDelete});

  @override
  State<DraftInlineEditorCard> createState() => _DraftInlineEditorCardState();
}

class _DraftInlineEditorCardState extends State<DraftInlineEditorCard> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _budgetController;
  final List<Map<String, TextEditingController>> _milestoneControllers = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project.title);
    _descController = TextEditingController(text: widget.project.description);
    _budgetController = TextEditingController(text: widget.project.totalBudget);

    for (var m in widget.project.milestones) {
      _milestoneControllers.add({
        'task': TextEditingController(text: m.taskName),
        'budget': TextEditingController(text: m.allocatedBudget),
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    for (var m in _milestoneControllers) {
      m['task']!.dispose();
      m['budget']!.dispose();
    }
    super.dispose();
  }

  void _syncAndPublish() {
    widget.project.title = _titleController.text;
    widget.project.description = _descController.text;
    widget.project.totalBudget = _budgetController.text;

    int loopCount = _milestoneControllers.length;
    if (widget.project.milestones.length < loopCount) loopCount = widget.project.milestones.length;

    for (int i = 0; i < loopCount; i++) {
      widget.project.milestones[i].taskName = _milestoneControllers[i]['task']!.text;
      widget.project.milestones[i].allocatedBudget = _milestoneControllers[i]['budget']!.text;
    }
    widget.onPublish();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF43A047), Color(0xFF2E7D32)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: const Text("Draft", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    const Text("Edit Details & Milestones", style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white), onPressed: widget.onDelete)
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("PROJECT TITLE", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: "Enter Title"),
                ),
                const Divider(),
                const Text("DESCRIPTION", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: "Enter Description"),
                ),
                const SizedBox(height: 12),
                const Text("TOTAL BUDGET (RM)", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: const [
                      Icon(Icons.flag, size: 16, color: Colors.black54),
                      SizedBox(width: 8),
                      Text("MILESTONES (Task & Allocation)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_milestoneControllers.isEmpty)
                  const Text("No milestones generated.", style: TextStyle(color: Colors.grey)),
                ...List.generate(_milestoneControllers.length, (i) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                    child: Row(
                      children: [
                        Container(
                          width: 24, height: 24, alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                          child: Text("${i+1}", style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _milestoneControllers[i]['task'],
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: "Task Name"),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _milestoneControllers[i]['budget'],
                            textAlign: TextAlign.end,
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, prefixText: "RM ", prefixStyle: TextStyle(fontSize: 12, color: Colors.grey)),
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _syncAndPublish,
                    child: const Text("Publish to Job Board", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}