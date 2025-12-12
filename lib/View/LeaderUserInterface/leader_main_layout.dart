// lib/views/leader_main_layout.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewModel/PlannerViewModel/planner_view_model.dart';
import '../../ViewModel/JobViewModule/job_view_model.dart';
import '../../models/project_model.dart';

// --- 1. 主框架 ---
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
      backgroundColor: const Color(0xFFF8F9FA), // 浅灰背景
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
          IconButton(icon: const Icon(Icons.person_outline, color: Colors.black), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _mainTabController,
              labelColor: const Color(0xFF2E7D32), // 深绿色
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2E7D32),
              isScrollable: false, // 固定Tab
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.smart_toy_outlined, size: 20), text: "AI Planner"),
                Tab(icon: Icon(Icons.assignment_outlined, size: 20), text: "Projects"),
                Tab(icon: Icon(Icons.bar_chart_outlined, size: 20), text: "Impact"),
                Tab(icon: Icon(Icons.groups_outlined, size: 20), text: "Community"),
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

// --- 2. AI Planner Section ---
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
                      Text("AI Resource Planner", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("Input available resources to generate project proposals.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          const Text("Quick Select Resources:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _quickInputChip("Empty Warehouse"),
            _quickInputChip("2 Acres Land"),
            _quickInputChip("Old Computers"),
            _quickInputChip("Community Hall"),
          ]),

          const SizedBox(height: 25),
          const Text("Describe your resources:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "E.g., We have an abandoned shed near the river and some leftover timber...",
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
              label: Text(viewModel.isLoading ? "Generating..." : "Generate Proposal"),
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
                  // 清空输入框以便下次输入
                  _controller.clear();
                }
              },
            ),
          ),
          if (viewModel.error != null)
            Padding(padding: const EdgeInsets.only(top: 10), child: Text(viewModel.error!, style: const TextStyle(color: Colors.red))),
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
        // 顶部子导航栏 (Draft / Active / Completed)
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
              // Draft Tab
              DraftView(onPublish: () {
                _subTabController.animateTo(1); // 发布成功后跳转 Active
              }),
              // Active Tab
              const ActiveProjectsView(),
              // Completed Tab
              const Center(child: Text("No completed projects.")),
            ],
          ),
        ),
      ],
    );
  }
}

// --- 4. Active Projects View (复刻你的 UI) ---
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
                const Text("No active projects", style: TextStyle(color: Colors.grey)),
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

  // 🔥 关键：根据你的截图设计的卡片样式
  Widget _buildActiveProjectCard(BuildContext context, Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // 轻微阴影
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 顶部绿色横条 (包含标题和状态)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32), // 顶部深绿色
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text("Active", style: TextStyle(color: Colors.white, fontSize: 10)),
                )
              ],
            ),
          ),

          // 2. 内容区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 描述
                Text(
                  project.description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // 信息行 (Timeline, Participants)
                Row(
                  children: [
                    _iconText(Icons.calendar_today_outlined, project.timeline),
                    const SizedBox(width: 20),
                    _iconText(Icons.people_outline, project.participantRange),
                  ],
                ),
                const SizedBox(height: 16),

                // 进度条 (模拟进度)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Progress", style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
                        Text("0%", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.0, // 初始进度为 0
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. 底部操作栏
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.visibility_outlined, size: 16, color: Colors.grey),
                    label: const Text("View Details", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    onPressed: () {},
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade200),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2E7D32)),
                    label: const Text("Manage", style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12)),
                    onPressed: () {
                      // 这里可以跳转到管理页面
                    },
                  ),
                ),
              ],
            ),
          )
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

// --- 5. Draft View (支持多 Draft 滑动浏览) ---
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
    final drafts = viewModel.drafts; // 获取所有草稿

    if (viewModel.isLoading) return const Center(child: CircularProgressIndicator());

    if (drafts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("No drafts yet", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            TextButton(
              child: const Text("Go to AI Planner"),
              onPressed: () {
                // 找到父级 TabController 切换到第一个 tab (比较hacky，建议通过callback)
                DefaultTabController.of(context)?.animateTo(0);
              },
            )
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text("You have ${drafts.length} draft proposal(s)", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          // 使用 PageView 实现横向滚动浏览多个 Draft
          child: PageView.builder(
            controller: _pageController,
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              // 倒序显示，让最新的 Draft 显示在最前面（或者你可以根据需求调整 list 顺序）
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
          // 卡片头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9), // 浅绿色背景
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(4)),
                  child: const Text("AI Draft", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () {
                    viewModel.removeDraft(index);
                  },
                )
              ],
            ),
          ),

          // 卡片内容 (可滚动)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(draft.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Text(draft.description, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  _infoRow("Timeline", draft.timeline, Icons.calendar_today),
                  const SizedBox(height: 10),
                  _infoRow("Participants", draft.participantRange, Icons.people_outline),

                  const SizedBox(height: 20),
                  const Text("Milestones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  ...draft.milestones.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text("${m.phaseName}: ${m.taskName}", style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),

          // 底部按钮区
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EditProjectScreen(draftIndex: index))
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Edit"),
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
                    child: const Text("Publish"),
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

// --- 6. Edit Project Screen ---
class EditProjectScreen extends StatefulWidget {
  final int draftIndex; // 传入要编辑的 Draft 索引
  const EditProjectScreen({super.key, required this.draftIndex});

  @override
  _EditProjectScreenState createState() => _EditProjectScreenState();
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
    // 获取指定索引的 Draft
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
    String verificationType = m?.verificationType ?? "leader";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? "Edit Milestone" : "Add Milestone"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: phaseController, decoration: const InputDecoration(labelText: "Phase (e.g. Day 1)")),
              TextField(controller: taskController, decoration: const InputDecoration(labelText: "Task Name")),
              TextField(controller: incentiveController, decoration: const InputDecoration(labelText: "Incentive (e.g. 50 Points)")),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: verificationType,
                decoration: const InputDecoration(labelText: "Verification Type"),
                items: const [
                  DropdownMenuItem(value: "leader", child: Text("Leader Confirmation")),
                  DropdownMenuItem(value: "photo", child: Text("Photo Evidence")),
                ],
                onChanged: (val) => verificationType = val!,
              ),
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
                verificationType: verificationType,
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
                const Text("Milestones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                leading: const Icon(Icons.flag_outlined, color: Colors.green),
                title: Text(m.taskName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("${m.phaseName} • ${m.incentive}"),
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
                      // 更新 ViewModel 中的指定 Draft
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