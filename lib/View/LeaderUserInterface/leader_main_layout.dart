import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewModel/PlannerViewModel/planner_view_model.dart';
import '../../ViewModel/JobViewModule/job_view_model.dart';
import '../../models/project_model.dart';

class LeaderMainLayout extends StatefulWidget {
  const LeaderMainLayout({super.key});

  @override
  _LeaderMainLayoutState createState() => _LeaderMainLayoutState();
}

class _LeaderMainLayoutState extends State<LeaderMainLayout> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 4, vsync: this);
  }

  void switchToProjectsTab() {
    _mainTabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Village Leader", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Kampung Baru", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ---------------------------------------------------------
          // UPDATED: Link Profile Icon to the new Profile Page
          // ---------------------------------------------------------
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaderProfilePage()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _mainTabController,
              labelColor: const Color(0xFF2E7D32),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2E7D32),
              isScrollable: false,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.smart_toy_outlined), text: "AI Planner"),
                Tab(icon: Icon(Icons.assignment_outlined), text: "Projects"),
                Tab(icon: Icon(Icons.bar_chart_outlined), text: "Impact"),
                Tab(icon: Icon(Icons.groups_outlined), text: "Community"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          AIPlannerSection(onGenerateSuccess: switchToProjectsTab),
          const ProjectsSection(),
          const Center(child: Text("Impact Dashboard (Coming Soon)")),
          const Center(child: Text("Community Hub (Coming Soon)")),
        ],
      ),
    );
  }
}

// --- 2. AI Planner (输入资源) ---
class AIPlannerSection extends StatefulWidget {
  final VoidCallback onGenerateSuccess;
  const AIPlannerSection({super.key, required this.onGenerateSuccess});

  @override
  State<AIPlannerSection> createState() => _AIPlannerSectionState();
}

class _AIPlannerSectionState extends State<AIPlannerSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PlannerViewModel>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF2E7D32)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Smart Resource Planner", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("Input your idle resources. AI will recommend a sustainable project.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          const Text("What resources are available?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _quickInputChip("2 acres river land"),
            _quickInputChip("Surplus Corn Seeds"),
            _quickInputChip("Old Community Hall"),
            _quickInputChip("Bamboo grove"),
          ]),

          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "E.g., I have 50kg of leftover fertilizer and a small plot of land near the school...",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: viewModel.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.lightbulb_outline),
              label: Text(viewModel.isLoading ? "Analyzing Resources..." : "Get AI Recommendation"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: viewModel.isLoading ? null : () async {
                if (_controller.text.isEmpty) return;
                await viewModel.generatePlan(_controller.text);
                if (viewModel.drafts.isNotEmpty) {
                  widget.onGenerateSuccess();
                  _controller.clear();
                }
              },
            ),
          ),
          if (viewModel.error != null)
            Padding(padding: const EdgeInsets.only(top: 10), child: Text("Error: ${viewModel.error}", style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _quickInputChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      shape: const StadiumBorder(),
      onPressed: () => setState(() => _controller.text += "$text, "),
    );
  }
}

// --- 3. Projects Section ---
class ProjectsSection extends StatefulWidget {
  const ProjectsSection({super.key});

  @override
  _ProjectsSectionState createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> with TickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _subTabController,
            labelColor: const Color(0xFF2E7D32),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2E7D32),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Drafts"),
              Tab(text: "Active"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              DraftView(onPublish: () {
                _subTabController.animateTo(1);
              }),
              const ActiveProjectsView(),
              const Center(child: Text("No completed projects.")),
            ],
          ),
        ),
      ],
    );
  }
}

// --- 4. Active Projects View ---
class ActiveProjectsView extends StatelessWidget {
  const ActiveProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    final jobViewModel = Provider.of<JobViewModel>(context);

    return StreamBuilder<List<Project>>(
      stream: jobViewModel.activeProjectsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final projects = snapshot.data ?? [];
        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("No active projects running.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            return _buildActiveProjectCard(context, projects[index]);
          },
        );
      },
    );
  }

  Widget _buildActiveProjectCard(BuildContext context, Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                      child: const Text("Active", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const Icon(Icons.edit, color: Colors.white, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  project.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  project.participantRange,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Overall Progress", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text("0%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: Colors.green.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text("${project.milestones.length} Milestones", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 16),
                const Text("Timeline", style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(project.timeline, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text("Provided Resources:", style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(
                  "Initial materials supplied by Leader.",
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {},
                    child: const Text("View Project Details", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// --- 5. Draft View (移除验证方式) ---
class DraftView extends StatefulWidget {
  final VoidCallback onPublish;
  const DraftView({super.key, required this.onPublish});

  @override
  State<DraftView> createState() => _DraftViewState();
}

class _DraftViewState extends State<DraftView> {
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PlannerViewModel>(context);
    final drafts = viewModel.drafts;

    if (viewModel.isLoading) return const Center(child: CircularProgressIndicator());
    if (drafts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("No recommendations yet", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text("AI Recommendation (${drafts.length})", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[drafts.length - 1 - index];
              return _buildDraftCard(context, viewModel, draft, drafts.length - 1 - index);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDraftCard(BuildContext context, PlannerViewModel viewModel, Project draft, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(4)),
                  child: const Text("Recommendation", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => viewModel.removeDraft(index),
                )
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(draft.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Text(draft.description, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),

                  const SizedBox(height: 20),
                  const Divider(),

                  _infoRow("Timeline", draft.timeline, Icons.calendar_today),
                  const SizedBox(height: 10),
                  _infoRow("Target Youth", draft.participantRange, Icons.people_outline),

                  const SizedBox(height: 20),
                  const Text("Proposed Milestones & Rewards", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  ...draft.milestones.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star_outline, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text("${m.phaseName}: ${m.taskName}\nReward: ${m.incentive}", style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditProjectScreen(draftIndex: index)));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Edit Plan"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await viewModel.publishDraft(index);
                      widget.onPublish();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text("Approve & Publish"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// --- 6. Edit Project Screen (移除 Verification Type 下拉框) ---
class EditProjectScreen extends StatefulWidget {
  final int draftIndex;
  const EditProjectScreen({super.key, required this.draftIndex});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  late TextEditingController _titleController;
  late TextEditingController _timelineController;
  late TextEditingController _skillsController;
  late TextEditingController _participantsController;
  late TextEditingController _descController;
  late List<Milestone> _tempMilestones;

  @override
  void initState() {
    super.initState();
    final draft = Provider.of<PlannerViewModel>(context, listen: false).drafts[widget.draftIndex];

    _titleController = TextEditingController(text: draft.title);
    _timelineController = TextEditingController(text: draft.timeline);
    _skillsController = TextEditingController(text: draft.skills.join(", "));
    _participantsController = TextEditingController(text: draft.participantRange);
    _descController = TextEditingController(text: draft.description);
    _tempMilestones = List.from(draft.milestones);
  }

  void _showMilestoneDialog({int? index}) {
    final isEditing = index != null;
    final m = isEditing ? _tempMilestones[index] : null;

    final phaseController = TextEditingController(text: m?.phaseName ?? "");
    final taskController = TextEditingController(text: m?.taskName ?? "");
    final incentiveController = TextEditingController(text: m?.incentive ?? "");
    // 移除 Verification type 的变量

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? "Edit Milestone" : "Add Milestone"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: phaseController, decoration: const InputDecoration(labelText: "Phase (e.g. Phase 1)")),
              TextField(controller: taskController, decoration: const InputDecoration(labelText: "Task Name")),
              TextField(controller: incentiveController, decoration: const InputDecoration(labelText: "Incentive (e.g. Seeds)")),
              // ⚠️ 移除 Verification Type Dropdown
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final newMilestone = Milestone(
                phaseName: phaseController.text,
                taskName: taskController.text,
                incentive: incentiveController.text,
                verificationType: 'leader', // 默认值
              );

              setState(() {
                if (isEditing) {
                  _tempMilestones[index] = newMilestone;
                } else {
                  _tempMilestones.add(newMilestone);
                }
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PlannerViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Proposal", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _inputField("Project Title *", _titleController),
            _inputField("Timeline", _timelineController),
            _inputField("Required Skills", _skillsController),
            _inputField("Youth Participants", _participantsController),
            _inputField("Description *", _descController, maxLines: 5),

            const SizedBox(height: 20),
            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Milestones & Incentives", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text("Add"),
                  onPressed: () => _showMilestoneDialog(),
                ),
              ],
            ),

            if (_tempMilestones.isEmpty)
              const Padding(padding: EdgeInsets.all(10), child: Text("No milestones yet.", style: TextStyle(color: Colors.grey))),

            ..._tempMilestones.asMap().entries.map((entry) {
              int idx = entry.key;
              Milestone m = entry.value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.emoji_events_outlined, color: Colors.orange),
                title: Text(m.taskName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("Reward: ${m.incentive}"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                  onPressed: () => _showMilestoneDialog(index: idx),
                ),
              );
            }),

            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      viewModel.updateDraft(
                        widget.draftIndex,
                        title: _titleController.text,
                        description: _descController.text,
                        milestones: _tempMilestones,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Save Changes"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NEW CLASS: LeaderProfilePage (Based on Figma image_bbd323.png)
// ---------------------------------------------------------------------------
class LeaderProfilePage extends StatelessWidget {
  const LeaderProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9), // Light grayish-blue background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- Profile Header ---
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF2E7D32), // Dark Green
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              "Dato' Seri Ahmad",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 4),
            const Text(
              "Village Leader",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFC8E6C9), // Light Green pill
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Kampung Baru",
                style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),

            const SizedBox(height: 32),

            // --- Stats Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("12", "Active\nProject", Icons.assignment_outlined, const Color(0xFFC8E6C9), const Color(0xFF2E7D32)),
                _buildStatCard("47", "Completed", Icons.check_circle_outline, const Color(0xFFE3F2FD), const Color(0xFF1E88E5)),
                _buildStatCard("156", "Youth Hired", Icons.people_outline, const Color(0xFFFFF3E0), const Color(0xFFFF9800)),
              ],
            ),

            const SizedBox(height: 32),

            // --- Contact Information ---
            _buildSectionHeader("Contact Information"),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(Icons.email_outlined, "Email", "ahmad.leader@gmail.com"),
                  const Divider(height: 1, indent: 60),
                  _buildInfoTile(Icons.phone_outlined, "Phone", "+60 12-345 6789"),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- Village Information ---
            _buildSectionHeader("Village Information"),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(Icons.location_on_outlined, "Village", "Kampung Baru"),
                  const Divider(height: 1, indent: 60),
                  _buildInfoTile(Icons.groups_outlined, "Population", "1250 Resident"),
                  const Divider(height: 1, indent: 60),
                  _buildInfoTile(Icons.access_time, "Year in Office", "8 Year"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String count, String label, IconData icon, Color bg, Color iconColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.grey[600], size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
    );
  }
}