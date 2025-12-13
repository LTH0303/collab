// lib/View/LeaderUserInterface/projects_section_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../ViewModel/PlannerViewModel/planner_view_model.dart';
import '../../ViewModel/ApplicationViewModel/application_view_model.dart';
import '../../models/project_model.dart';
import '../../models/application_model.dart';
import '../../models/DatabaseService/database_service.dart';

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
        // Ensure we pass the project properly to the card
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
    return GestureDetector(
      onTap: () => _showActiveProjectDetails(context, project),
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
                  const Icon(Icons.visibility, color: Colors.white, size: 20)
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
                  const SizedBox(height: 16),
                  const Text("Tap to view applications & progress", style: TextStyle(fontSize: 12, color: Colors.blue)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showActiveProjectDetails(BuildContext context, Project project) {
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

              Text(project.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              if (project.id != null)
                _buildPendingApplicationsSection(context, project.id!),

              const Divider(height: 40),
              const Text("Milestones Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: project.milestones.asMap().entries.map((entry) {
                    var m = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(m.isCompleted ? Icons.check_circle : Icons.circle_outlined, color: m.isCompleted ? Colors.green : Colors.grey),
                        title: Text(m.taskName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Allocated: RM ${m.allocatedBudget}"),
                      ),
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

  Widget _buildPendingApplicationsSection(BuildContext context, String projectId) {
    final appViewModel = Provider.of<ApplicationViewModel>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pending Applications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: StreamBuilder<List<Application>>(
            stream: appViewModel.getProjectApplications(projectId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: const Text("No pending applications.", style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final app = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
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
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- FIXED DRAFT INLINE EDITOR CARD ---
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
  // Use a growable list for milestone controllers
  final List<Map<String, TextEditingController>> _milestoneControllers = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project.title);
    _descController = TextEditingController(text: widget.project.description);
    _budgetController = TextEditingController(text: widget.project.totalBudget);

    // Initialize controllers for existing milestones
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
    // 1. Sync basic info
    widget.project.title = _titleController.text;
    widget.project.description = _descController.text;
    widget.project.totalBudget = _budgetController.text;

    // 2. Sync Milestones
    // IMPORTANT: Ensure we don't go out of bounds if list sizes differ
    int loopCount = _milestoneControllers.length;
    if (widget.project.milestones.length < loopCount) loopCount = widget.project.milestones.length;

    for (int i = 0; i < loopCount; i++) {
      widget.project.milestones[i].taskName = _milestoneControllers[i]['task']!.text;
      widget.project.milestones[i].allocatedBudget = _milestoneControllers[i]['budget']!.text;
    }

    // 3. Call publish
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
          // Header
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

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text("PROJECT TITLE", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: "Enter Title"),
                ),
                const Divider(),

                // Description
                const Text("DESCRIPTION", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: "Enter Description"),
                ),
                const SizedBox(height: 12),

                // Budget
                const Text("TOTAL BUDGET (RM)", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                ),
                const SizedBox(height: 20),

                // Milestones Header
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

                // Milestones List - FIX: Use a fixed height or shrinkwrap properly
                // We use a Column of children instead of nested ListView to avoid scrolling conflicts if possible
                // or just shrinkwrap.
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
                }
                ),

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