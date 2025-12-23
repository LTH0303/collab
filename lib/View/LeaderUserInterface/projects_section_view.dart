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
import 'completed_project_page.dart';
import 'project_details_page.dart';

class ProjectsSection extends StatefulWidget {
  const ProjectsSection({super.key});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.95);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PlannerViewModel>(context);

    // FIXED: Clear error immediately after showing it to prevent loop
    if (viewModel.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(viewModel.error!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ));
        viewModel.clearError(); // <--- IMPORTANT FIX
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

  // UPDATED: Now fetches drafts from Firestore via StreamBuilder
  Widget _buildDraftsList(PlannerViewModel viewModel) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<List<Project>>(
      stream: DatabaseService().getLeaderProjects(user.uid, 'draft'),
      builder: (context, snapshot) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final drafts = snapshot.data ?? [];

        if (drafts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.post_add, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("No drafts found.", style: TextStyle(fontSize: 14, color: Colors.grey)),
                const Text("Use AI Planner to create one.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Text("Plan your projects before publishing", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: drafts.length,
                itemBuilder: (context, index) {
                  // Display newest drafts first or based on DB order
                  final draft = drafts[index];
                  return _buildDraftPage(context, viewModel, draft);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // UPDATED: Draft Page Builder uses project.id
  Widget _buildDraftPage(BuildContext context, PlannerViewModel viewModel, Project draft) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // --- Main Project Info Card ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7986CB), Color(0xFF2E7D32)], // Purple to Greenish
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _tag("Draft", Colors.white.withOpacity(0.2)),
                          const SizedBox(width: 8),
                          _tag("AI Generated", Colors.white.withOpacity(0.2)),
                          const Spacer(),
                          // EDIT BUTTON ACTION
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              if (draft.id != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProjectPage(project: draft, projectId: draft.id!),
                                  ),
                                );
                              }
                            },
                          ),
                          // DELETE BUTTON ACTION
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                            onPressed: () {
                              if (draft.id != null) {
                                viewModel.removeDraft(draft.id!);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        draft.title,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("Timeline"),
                      Text(draft.timeline, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 16),
                      _sectionTitle("Total Budget"),
                      Text("RM ${draft.totalBudget}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),

                      const SizedBox(height: 16),
                      _sectionTitle("Required Skills"),
                      Wrap(
                        spacing: 8,
                        children: draft.skills.map((s) => Chip(
                          label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                      ),

                      const SizedBox(height: 16),
                      _sectionTitle("Youth Participants Needed"),
                      Text(draft.participantRange, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 16),
                      _sectionTitle("Starting Materials"),
                      Text(
                        draft.startingResources.join(", "),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),

                      const SizedBox(height: 16),
                      _sectionTitle("Address"),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(draft.address, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                        ],
                      ),

                      const SizedBox(height: 16),
                      _sectionTitle("Project Description"),
                      Text(draft.description, style: const TextStyle(fontSize: 13, height: 1.5, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- Task Milestones (Outside Card) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Task Milestones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: draft.milestones.length,
                  itemBuilder: (context, mIndex) {
                    final milestone = draft.milestones[mIndex];
                    final isLast = mIndex == draft.milestones.length - 1;
                    return _buildTimelineItem(context, milestone, isLast);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- PUBLISH BUTTON ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (draft.id != null) {
                    await viewModel.publishDraft(draft.id!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Publish to Job Board", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, Milestone milestone, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line & Dot
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(milestone.taskName),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Phase: ${milestone.phaseName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(milestone.description),
                          const SizedBox(height: 10),
                          const Text("Incentive:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(milestone.incentive, style: const TextStyle(color: Colors.orange)),
                          const SizedBox(height: 10),
                          const Text("Allocated Budget:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("RM ${milestone.allocatedBudget}", style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${milestone.phaseName}: ${milestone.taskName}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Incentive: ${milestone.incentive}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Text(
                        "Budget: RM ${milestone.allocatedBudget}",
                        style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<List<Project>>(
      stream: DatabaseService().getLeaderProjects(user.uid, 'completed'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final projects = List<Project>.from(snapshot.data ?? []);
        projects.sort((a, b) {
          final aDate = a.completedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.completedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        if (projects.isEmpty) {
          return const Center(
            child: Text("No completed projects yet.", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompletedProjectDashboardPage(project: project),
                ),
              ),
              child: CompletedProjectDashboardCard(project: project),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveCard(BuildContext context, Project project) {
    bool hasPendingReview = project.milestones.any((m) => m.hasPendingReviews);
    bool isProjectStarted = project.milestones.isNotEmpty && (project.milestones[0].isOpen || project.milestones[0].isCompleted);
    final appViewModel = Provider.of<ApplicationViewModel>(context, listen: false);

    return Container(
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
          GestureDetector(
            onTap: () => _navigateToProjectDetails(context, project),
            child: Padding(
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
          ),
          GestureDetector(
            onTap: () {}, // Empty handler to stop propagation
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: StreamBuilder<List<Application>>(
                      stream: appViewModel.getProjectApplications(project.id!),
                      builder: (context, snapshot) {
                        int pendingAppCount = snapshot.hasData ? snapshot.data!.length : 0;
                        return ElevatedButton.icon(
                          onPressed: pendingAppCount > 0
                              ? () => _navigateToPendingApprovals(context, project)
                              : null,
                          icon: const Icon(Icons.pending_actions, size: 18),
                          label: Text("Pending Approvals${pendingAppCount > 0 ? ' ($pendingAppCount)' : ''}"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pendingAppCount > 0 ? Colors.orange : Colors.grey.shade300,
                            foregroundColor: pendingAppCount > 0 ? Colors.white : Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToProjectDetails(context, project),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text("View Details"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPendingApprovals(BuildContext context, Project project) {
    if (project.id != null) {
      _showPendingApplicationsPopup(context, project.id!, project.title);
    }
  }

  void _showPendingApplicationsPopup(BuildContext context, String projectId, String projectTitle) {
    final appViewModel = Provider.of<ApplicationViewModel>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                Expanded(
                  child: Text(
                    "Pending Applications",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Application>>(
                stream: appViewModel.getProjectApplications(projectId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "No pending applications.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final app = snapshot.data![index];
                      final state = app.state;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Applicant Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.applicantName.isNotEmpty && app.applicantName != "Unknown"
                                          ? app.applicantName
                                          : "Participant ${app.applicantId.substring(0, 8)}...",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Applied: ${app.appliedAt.toString().substring(0, 10)}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Action Buttons
                              if (state.isLeaderActionable)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ApplicantProfileView(application: app),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.visibility_outlined, size: 20),
                                      color: Colors.blue,
                                      tooltip: "View Profile",
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      onPressed: () => appViewModel.rejectApplicant(app),
                                      icon: const Icon(Icons.close, size: 20),
                                      color: Colors.red,
                                      tooltip: "Reject",
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      onPressed: () => appViewModel.approveApplicant(app),
                                      icon: const Icon(Icons.check, size: 20),
                                      color: Colors.green,
                                      tooltip: "Approve",
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.green.shade50,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ApplicantProfileView(application: app),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.visibility_outlined, size: 20),
                                      color: Colors.blue,
                                      tooltip: "View Profile",
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: state.displayColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        state.labelText,
                                        style: TextStyle(
                                          color: state.displayColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProjectDetails(BuildContext context, Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailsPage(project: project),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NEW CLASS: EditProjectPage (Updated to use DB via ViewModel)
// ---------------------------------------------------------------------------
class EditProjectPage extends StatefulWidget {
  final Project project;
  final String projectId; // Changed from index to ID

  const EditProjectPage({super.key, required this.project, required this.projectId});

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _timelineController;
  late TextEditingController _skillsController;
  late TextEditingController _participantsController;
  late TextEditingController _materialsController;
  late TextEditingController _descController;
  late TextEditingController _addressController;
  late TextEditingController _budgetController;

  late List<Milestone> _milestones;

  @override
  void initState() {
    super.initState();
    // Initialize with draft data
    _titleController = TextEditingController(text: widget.project.title);
    _timelineController = TextEditingController(text: widget.project.timeline);
    _skillsController = TextEditingController(text: widget.project.skills.join(", "));
    _participantsController = TextEditingController(text: widget.project.participantRange);
    _materialsController = TextEditingController(text: widget.project.startingResources.join(", "));
    _descController = TextEditingController(text: widget.project.description);
    _addressController = TextEditingController(text: widget.project.address);
    _budgetController = TextEditingController(text: widget.project.totalBudget);

    // Deep copy milestones so edits don't reflect immediately until saved
    _milestones = widget.project.milestones.map((m) => Milestone(
      phaseName: m.phaseName,
      taskName: m.taskName,
      verificationType: m.verificationType,
      incentive: m.incentive,
      description: m.description,
      allocatedBudget: m.allocatedBudget,
    )).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timelineController.dispose();
    _skillsController.dispose();
    _participantsController.dispose();
    _materialsController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // 1. Prepare Data
    final updatedSkills = _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final updatedMaterials = _materialsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final plannerVM = Provider.of<PlannerViewModel>(context, listen: false);

    final updatedData = {
      'project_title': _titleController.text,
      'timeline': _timelineController.text,
      'required_skills': updatedSkills,
      'participant_range': _participantsController.text,
      'starting_resources': updatedMaterials,
      'description': _descController.text,
      'address': _addressController.text,
      'total_budget': _budgetController.text,
      'milestones': _milestones.map((m) => m.toJson()).toList(),
    };

    // 2. Call ViewModel to update DB
    await plannerVM.updateDraft(widget.projectId, updatedData);

    if (mounted) Navigator.pop(context);
  }

  void _addNewMilestone() {
    final taskCtrl = TextEditingController();
    final phaseCtrl = TextEditingController();
    final incentiveCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Milestone"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: phaseCtrl, decoration: const InputDecoration(labelText: "Phase (e.g. Day 1)")),
              TextField(controller: taskCtrl, decoration: const InputDecoration(labelText: "Task Name")),
              TextField(controller: incentiveCtrl, decoration: const InputDecoration(labelText: "Incentive")),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description"), maxLines: 3),
              TextField(controller: budgetCtrl, decoration: const InputDecoration(labelText: "Allocated Budget (RM)"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (taskCtrl.text.isNotEmpty && phaseCtrl.text.isNotEmpty) {
                setState(() {
                  _milestones.add(Milestone(
                    phaseName: phaseCtrl.text,
                    taskName: taskCtrl.text,
                    verificationType: "Photo",
                    incentive: incentiveCtrl.text,
                    description: descCtrl.text,
                    allocatedBudget: budgetCtrl.text.isEmpty ? "0" : budgetCtrl.text,
                  ));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editMilestone(int index) {
    final m = _milestones[index];
    final taskCtrl = TextEditingController(text: m.taskName);
    final phaseCtrl = TextEditingController(text: m.phaseName);
    final incentiveCtrl = TextEditingController(text: m.incentive);
    final descCtrl = TextEditingController(text: m.description);
    final budgetCtrl = TextEditingController(text: m.allocatedBudget);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Milestone"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: phaseCtrl, decoration: const InputDecoration(labelText: "Phase (e.g. Day 1)")),
              TextField(controller: taskCtrl, decoration: const InputDecoration(labelText: "Task Name")),
              TextField(controller: incentiveCtrl, decoration: const InputDecoration(labelText: "Incentive")),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description"), maxLines: 3),
              TextField(controller: budgetCtrl, decoration: const InputDecoration(labelText: "Allocated Budget (RM)"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _milestones[index] = Milestone(
                  phaseName: phaseCtrl.text,
                  taskName: taskCtrl.text,
                  verificationType: m.verificationType,
                  incentive: incentiveCtrl.text,
                  description: descCtrl.text,
                  allocatedBudget: budgetCtrl.text.isEmpty ? "0" : budgetCtrl.text,
                );
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Project", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF2E7D32)),
            onPressed: _saveChanges,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Project Title *"),
            _buildTextField(_titleController, "e.g. Community Organic Farming"),

            const SizedBox(height: 16),
            _buildLabel("Total Budget (RM) *"),
            _buildTextField(_budgetController, "e.g. 5000", maxLines: 1),

            const SizedBox(height: 16),
            _buildLabel("Timeline"),
            _buildTextField(_timelineController, "e.g. 3-4 months"),

            const SizedBox(height: 16),
            _buildLabel("Required Skills (Comma-separated)"),
            _buildTextField(_skillsController, "e.g. Agriculture, Manual Labor"),

            const SizedBox(height: 16),
            _buildLabel("Youth Participants"),
            _buildTextField(_participantsController, "e.g. 5-8 participants"),

            const SizedBox(height: 16),
            _buildLabel("Starting Materials (Comma-separated)"),
            _buildTextField(_materialsController, "e.g. 2 plots of land, 10 pack seeds"),

            const SizedBox(height: 16),
            _buildLabel("Address"),
            _buildTextField(_addressController, "e.g. Kampung Baru, Lot 123"),

            const SizedBox(height: 16),
            _buildLabel("Project Description *"),
            _buildTextField(_descController, "Describe the project goals...", maxLines: 5),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Milestones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addNewMilestone,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add"),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF2E7D32)),
                )
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _milestones.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final m = _milestones[index];
                  return ListTile(
                    title: Text("${m.phaseName}: ${m.taskName}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text("${m.incentive} • RM ${m.allocatedBudget}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _milestones.removeAt(index);
                        });
                      },
                    ),
                    onTap: () => _editMilestone(index),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: const BorderSide(color: Colors.black),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Colors.black, fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
        ),
      ),
    );
  }
}