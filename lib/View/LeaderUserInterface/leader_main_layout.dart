import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewModel/PlannerViewModel/planner_view_model.dart';
import 'leader_profile_page.dart';
import 'projects_section_view.dart';
import '../CommunityInterface/community_hub_page.dart'; // Import the new community page
import 'impact_overview_page.dart';

class LeaderMainLayout extends StatefulWidget {
  final int? initialTab;
  final int? initialSubTab; // For ProjectsSection sub-tabs (0=Draft, 1=Active, 2=Completed)
  final String? prefillResources;
  final String? prefillBudget;

  const LeaderMainLayout({
    super.key,
    this.initialTab,
    this.initialSubTab,
    this.prefillResources,
    this.prefillBudget,
  });

  @override
  _LeaderMainLayoutState createState() => _LeaderMainLayoutState();
}

// Wrapper class to handle navigation with data
class LeaderMainLayoutWithData extends StatelessWidget {
  final int initialTab;
  final int? initialSubTab;
  final String? prefillResources;
  final String? prefillBudget;

  const LeaderMainLayoutWithData({
    super.key,
    required this.initialTab,
    this.initialSubTab,
    this.prefillResources,
    this.prefillBudget,
  });

  @override
  Widget build(BuildContext context) {
    return LeaderMainLayout(
      initialTab: initialTab,
      initialSubTab: initialSubTab,
      prefillResources: prefillResources,
      prefillBudget: prefillBudget,
    );
  }
}

// Wrapper class to navigate to Projects tab with specific sub-tab
class LeaderMainLayoutWithProjectsTab extends StatelessWidget {
  final int initialSubTab; // 0 = Draft, 1 = Active, 2 = Completed

  const LeaderMainLayoutWithProjectsTab({
    super.key,
    required this.initialSubTab,
  });

  @override
  Widget build(BuildContext context) {
    return LeaderMainLayout(
      initialTab: 1, // Projects tab
      initialSubTab: initialSubTab,
    );
  }
}

class _LeaderMainLayoutState extends State<LeaderMainLayout> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Switch to specified tab if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTab != null) {
        _tabController.animateTo(widget.initialTab!);
      }
    });
  }

  void switchToProjectsTab() {
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.home, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Village Leader", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Kampung Baru", style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderProfilePage())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2E7D32),
          tabs: const [
            Tab(text: "AI Planner"),
            Tab(text: "Projects"),
            Tab(text: "Impact"),
            Tab(text: "Community"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          AIPlannerSection(
            onGenerateSuccess: switchToProjectsTab,
            prefillResources: widget.prefillResources,
            prefillBudget: widget.prefillBudget,
          ),
          ProjectsSection(initialSubTab: widget.initialSubTab),
          const ImpactOverviewPage(),
          const CommunityHubPage(), // <--- Added here
        ],
      ),
    );
  }
}

// --- AI Planner Section ---
class AIPlannerSection extends StatefulWidget {
  final VoidCallback onGenerateSuccess;
  final String? prefillResources;
  final String? prefillBudget;

  const AIPlannerSection({
    super.key,
    required this.onGenerateSuccess,
    this.prefillResources,
    this.prefillBudget,
  });

  @override
  State<AIPlannerSection> createState() => _AIPlannerSectionState();
}

class _AIPlannerSectionState extends State<AIPlannerSection> {
  late final TextEditingController _resourceController;
  late final TextEditingController _budgetController;

  @override
  void initState() {
    super.initState();
    _resourceController = TextEditingController(text: widget.prefillResources ?? '');
    _budgetController = TextEditingController(text: widget.prefillBudget ?? '');
  }

  @override
  void dispose() {
    _resourceController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _addQuickInput(String text) {
    if (_resourceController.text.isEmpty) {
      _resourceController.text = text;
    } else {
      _resourceController.text = "${_resourceController.text}, $text";
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PlannerViewModel>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF5C6BC0), Color(0xFF26A69A)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("AI Resource Planner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("Tell me about your available resources, and I'll suggest the best community projects.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text("Quick Inputs:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildQuickInputButton("2 acres abandoned river land"),
              _buildQuickInputButton("Seasonal crop surplus"),
              _buildQuickInputButton("Unused community hall"),
              _buildQuickInputButton("5 idle tractors"),
            ],
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _resourceController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Describe your available resources...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: "RM ",
              hintText: "Total Grant Budget",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              onPressed: viewModel.isLoading ? null : () async {
                if (_resourceController.text.isEmpty || _budgetController.text.isEmpty) return;

                // 收起键盘
                FocusScope.of(context).unfocus();

                await viewModel.generatePlan(_resourceController.text, _budgetController.text);

                // UPDATED: 检查是否有错误，而不是检查本地 drafts 列表
                // 因为现在直接存入数据库，没有本地列表了
                if (viewModel.error == null) {
                  widget.onGenerateSuccess();
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${viewModel.error}"), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(viewModel.isLoading ? "Generating..." : "Generate Proposal", style: const TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickInputButton(String text) {
    return OutlinedButton(
      onPressed: () => _addQuickInput(text),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Colors.grey),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black87, fontSize: 12),
      ),
    );
  }
}