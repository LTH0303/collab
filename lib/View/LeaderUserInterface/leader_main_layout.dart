// lib/views/leader_main_layout.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewModel/PlannerViewModel/planner_view_model.dart';
import '../../models/project_model.dart';

// --- 1. 主框架：处理蓝色圈的导航 (AI Planner, Projects, etc.) ---
class LeaderMainLayout extends StatefulWidget {
  @override
  _LeaderMainLayoutState createState() => _LeaderMainLayoutState();
}

class _LeaderMainLayoutState extends State<LeaderMainLayout> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    // 定义4个主标签: AI Planner, Projects, Impact, Community
    _mainTabController = TabController(length: 4, vsync: this);
  }

  // 供外部调用：跳转到 Projects 页面 (Index 1)
  void switchToProjectsTab() {
    _mainTabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // 背景色微灰，更有质感
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Village Leader", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Kampung Baru", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.person_outline, color: Colors.black), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _mainTabController,
              labelColor: Colors.green[800],
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              isScrollable: true, // 允许左右滑动如果屏幕小
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(icon: Icon(Icons.smart_toy, size: 18), text: "AI Planner"),
                Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: "Projects"), // 蓝色圈的目标
                Tab(icon: Icon(Icons.bar_chart, size: 18), text: "Impact"),
                Tab(icon: Icon(Icons.groups, size: 18), text: "Community"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        physics: NeverScrollableScrollPhysics(), // 禁止左右滑动切换，防止误触
        children: [
          // Tab 0: AI Planner 输入页
          AIPlannerSection(onGenerateSuccess: switchToProjectsTab),

          // Tab 1: Projects 页 (包含绿色圈子标签)
          ProjectsSection(),

          // Tab 2: Impact (Empty)
          Center(child: Text("Impact Dashboard (Coming Soon)")),

          // Tab 3: Community (Empty)
          Center(child: Text("Community Hub (Coming Soon)")),
        ],
      ),
    );
  }
}

// --- 2. AI Planner 输入部分 ---
class AIPlannerSection extends StatefulWidget {
  final VoidCallback onGenerateSuccess;
  AIPlannerSection({required this.onGenerateSuccess});

  @override
  State<AIPlannerSection> createState() => _AIPlannerSectionState();
}

class _AIPlannerSectionState extends State<AIPlannerSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PlannerViewModel>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 紫绿色渐变卡片
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo.shade300, Colors.teal.shade700]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 32),
                SizedBox(height: 10),
                Text("AI Resource Planner", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text("Tell me about your available resources, and I'll suggest the best community projects.",
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          SizedBox(height: 30),

          Text("Quick Inputs:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _quickInputChip("2 acres abandoned river land"),
            _quickInputChip("Seasonal crop surplus"),
            _quickInputChip("Unused community hall"),
            _quickInputChip("5 idle tractors"),
          ]),

          SizedBox(height: 30),
          // 输入框
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Describe your available resources...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 10),
              // 生成按钮
              Container(
                decoration: BoxDecoration(color: Colors.green[800], borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: viewModel.isLoading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(Icons.arrow_outward, color: Colors.white),
                  onPressed: () async {
                    if (_controller.text.isEmpty) return;
                    await viewModel.generatePlan(_controller.text);
                    if (viewModel.currentDraft != null) {
                      // 生成成功，跳转到 Projects Tab
                      widget.onGenerateSuccess();
                    }
                  },
                ),
              )
            ],
          ),
          if (viewModel.error != null)
            Padding(padding: EdgeInsets.only(top: 10), child: Text(viewModel.error!, style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _quickInputChip(String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade300)),
      onPressed: () => setState(() => _controller.text += "$text, "),
    );
  }
}

// --- 3. Projects 页面 (处理绿色圈: Draft / Active / Completed) ---
class ProjectsSection extends StatefulWidget {
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
        // 绿色圈的子导航 (Sub-tabs)
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(25)),
          child: TabBar(
            controller: _subTabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            indicator: BoxDecoration(color: Colors.green[700], borderRadius: BorderRadius.circular(25)),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent, // 去除下划线
            tabs: [
              Tab(text: "Draft"),
              Tab(text: "Active"),
              Tab(text: "Completed"),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              // Draft Tab: 显示 AI 生成的内容
              DraftView(onPublish: () {
                // 发布后跳转到 Active Tab
                _subTabController.animateTo(1);
              }),

              // Active Tab (暂为空)
              Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 50, color: Colors.green),
                  SizedBox(height: 10),
                  Text("Project is now Active!"),
                  Text("(Participants can apply now)", style: TextStyle(color: Colors.grey)),
                ],
              )),

              // Completed Tab (暂为空)
              Center(child: Text("No completed projects yet.")),
            ],
          ),
        )
      ],
    );
  }
}

// --- 4. Draft View (AI 生成结果展示 - 核心修改区) ---
class DraftView extends StatelessWidget {
  final VoidCallback onPublish;
  DraftView({required this.onPublish});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PlannerViewModel>(context);
    final draft = viewModel.currentDraft;

    if (viewModel.isLoading) return Center(child: CircularProgressIndicator());
    if (draft == null) return Center(child: Text("No draft yet. Go to AI Planner to generate one."));

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Plan your projects before publishing", style: TextStyle(color: Colors.grey)),
          SizedBox(height: 10),

          // 绿色渐变卡片 - 头部
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo.shade400, Colors.teal.shade700]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _tag("Draft", Colors.white24),
                          SizedBox(width: 8),
                          _tag("AI Generated", Colors.white24),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(draft.title, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                // 编辑按钮 (跳转到 Edit 页面)
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => EditProjectScreen()));
                  },
                )
              ],
            ),
          ),

          // 白色卡片 - 详情内容
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("Timeline", draft.timeline),
                SizedBox(height: 15),
                Text("Required Skills", style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 5),
                Wrap(spacing: 8, children: draft.skills.map((s) => _skillChip(s)).toList()),
                SizedBox(height: 15),
                _infoRow("Youth Participants Needed", draft.participantRange),

                // 🔴 关键修改：移除了 Compensation 行

                SizedBox(height: 15),
                Text("Project Description", style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 5),
                Text(draft.description, style: TextStyle(fontWeight: FontWeight.w500)),

                SizedBox(height: 20),
                Divider(),

                // --- Milestone 列表 (不显示 Status Badge) ---
                Text("Task Milestones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: draft.milestones.length,
                  itemBuilder: (context, index) {
                    final m = draft.milestones[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 简单的圆点连线效果
                          Column(
                            children: [
                              CircleAvatar(radius: 6, backgroundColor: Colors.teal),
                              if (index != draft.milestones.length - 1)
                                Container(width: 2, height: 30, color: Colors.grey[300]),
                            ],
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${m.phaseName}: ${m.taskName}", style: TextStyle(fontWeight: FontWeight.bold)),
                                // 只显示奖励，不显示 Upload Photo 等 Tag
                                Text("Incentive: ${m.incentive}", style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 20),
                // Publish 按钮
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await viewModel.publishCurrentDraft();
                      onPublish(); // 触发跳转到 Active 标签
                    },
                    child: Text("Publish to Job Board", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _skillChip(String label) {
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: Colors.black87,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

// --- 5. Edit 页面 (编辑内容，移除 Compensation) ---
class EditProjectScreen extends StatefulWidget {
  @override
  _EditProjectScreenState createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  late TextEditingController _titleController;
  late TextEditingController _timelineController;
  late TextEditingController _skillsController;
  late TextEditingController _participantsController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    final draft = Provider.of<PlannerViewModel>(context, listen: false).currentDraft!;
    _titleController = TextEditingController(text: draft.title);
    _timelineController = TextEditingController(text: draft.timeline);
    _skillsController = TextEditingController(text: draft.skills.join(", "));
    _participantsController = TextEditingController(text: draft.participantRange);
    _descController = TextEditingController(text: draft.description);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PlannerViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Edit Project", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context))
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ListView(
          children: [
            _inputField("Project Title *", _titleController),
            _inputField("Timeline", _timelineController),
            _inputField("Required Skills (Comma-separated)", _skillsController),
            _inputField("Youth Participants", _participantsController),

            // 🔴 关键修改：移除了 Compensation 输入框

            _inputField("Project Description *", _descController, maxLines: 5),

            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[800],
                        padding: EdgeInsets.symmetric(vertical: 15)
                    ),
                    onPressed: () {
                      // 保存逻辑
                      viewModel.updateTitle(_titleController.text);
                      viewModel.updateDescription(_descController.text);
                      // 这里还可以加 updateTimeline, updateSkills 等逻辑
                      Navigator.pop(context);
                    },
                    child: Text("Save Changes", style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel", style: TextStyle(color: Colors.black)),
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
          SizedBox(height: 5),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}