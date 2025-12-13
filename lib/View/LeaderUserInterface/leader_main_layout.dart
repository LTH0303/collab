import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for logout
import '../Authentication/login_page.dart'; // Added for navigation
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
          // Link Profile Icon to the Profile Page
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

// --- 2. AI Planner ---
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

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A85B6), Color(0xFF2E7D32)], // Blueish purple to Green
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("AI Resource Planner", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text("Tell me about your available resources, and I'll suggest the best community projects.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Quick Inputs
              const Text("Quick Inputs:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 16),

              // 2x2 Grid Layout for Quick Inputs
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5, // Adjust aspect ratio for card shape
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _quickInputCard("2 acres abandoned\nriver land"),
                  _quickInputCard("Seasonal crop\nsurplus"),
                  _quickInputCard("Unused community hall"),
                  _quickInputCard("5 idle tractors"),
                ],
              ),

              // Space for bottom text field
              const SizedBox(height: 100),
            ],
          ),
        ),

        // Bottom Input Field (Floating)
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 5))
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Describe your available resources...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                viewModel.isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : GestureDetector(
                  onTap: () async {
                    if (_controller.text.isEmpty) return;
                    await viewModel.generatePlan(_controller.text);
                    if (viewModel.drafts.isNotEmpty) {
                      widget.onGenerateSuccess();
                      _controller.clear();
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFA8C0B0), Color(0xFF6A8E78)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickInputCard(String text) {
    return GestureDetector(
      onTap: () {
        // Append text to controller
        String newText = text.replaceAll('\n', ' ');
        if (_controller.text.isNotEmpty) {
          _controller.text += ", $newText";
        } else {
          _controller.text = newText;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
      ),
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
}


// --- 5. Draft View (Updated UI - Image 2) ---
class DraftView extends StatefulWidget {
  final VoidCallback onPublish;
  const DraftView({super.key, required this.onPublish});

  @override
  State<DraftView> createState() => _DraftViewState();
}

class _DraftViewState extends State<DraftView> {
  final PageController _pageController = PageController(viewportFraction: 0.95);

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
            const Text("Plan your projects before publishing", style: TextStyle(fontSize: 14, color: Colors.grey)),
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
              final draft = drafts[drafts.length - 1 - index];
              return _buildDraftPage(context, viewModel, draft, drafts.length - 1 - index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDraftPage(BuildContext context, PlannerViewModel viewModel, Project draft, int index) {
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
                          const Icon(Icons.edit, color: Colors.white),
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
                      _sectionTitle("Starting Materials"), // New Section
                      // Combine user input and AI additions logic is handled in AI service, here we just display
                      Text(
                        draft.startingResources.join(", "),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),

                      const SizedBox(height: 16),
                      _sectionTitle("Address"), // New Section
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

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            await viewModel.publishDraft(index);
                            widget.onPublish();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Publish to Job Board", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
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
                  color: Colors.grey.shade300, // Grey for Draft status
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
                  // Show details dialog
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
                        ],
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE), // Light grey bg for milestone item
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
                        "Incentive: ${milestone.incentive}", // Fixed "Indicated" typo
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
}

// ---------------------------------------------------------------------------
// NEW CLASS: LeaderProfilePage
// ---------------------------------------------------------------------------
class LeaderProfilePage extends StatelessWidget {
  const LeaderProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
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
          // -----------------------------------------------------------
          // UPDATED: Added Logout Button Logic here
          // -----------------------------------------------------------
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                // Navigate back to Login Page and clear the navigation stack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                );
              }
            },
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
                color: const Color(0xFFC8E6C9),
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