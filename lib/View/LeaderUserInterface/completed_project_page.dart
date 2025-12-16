import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ProjectRepository/project_model.dart';
import '../../ViewModel/ProjectDetailsViewModel/completed_project_view_model.dart';
import '../../ViewModel/PlannerViewModel/planner_view_model.dart';
import 'project_details_page.dart';

class CompletedProjectDashboardContent extends StatefulWidget {
  final CompletedProjectDashboardViewModel viewModel;
  final Project project;
  final bool showHeader;

  const CompletedProjectDashboardContent({
    super.key,
    required this.viewModel,
    required this.project,
    this.showHeader = true,
  });

  // --- STATIC HEADER BUILDER ---
  // Moved here so it can be accessed by the Card and Page classes
  static Widget buildHeader(Project project, {BorderRadius? borderRadius, bool addShadow = true}) {
    final completedCount = project.milestones.where((m) => m.isCompleted).length;
    final totalCount = project.milestones.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF5C6BC0), Color(0xFF8E24AA)]),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: addShadow
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                child: const Text("Completed",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Text("$completedCount/$totalCount milestones",
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(project.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  State<CompletedProjectDashboardContent> createState() => _CompletedProjectDashboardContentState();
}

class _CompletedProjectDashboardContentState extends State<CompletedProjectDashboardContent> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          CompletedProjectDashboardContent.buildHeader(
            widget.project,
            borderRadius: BorderRadius.circular(12),
            addShadow: false,
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          "Final Impact Metrics",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildTopImpactSection(context, widget.viewModel),
        const SizedBox(height: 20),
        _buildSkillsSection(widget.project),
        const SizedBox(height: 20),
        _buildProjectInfoSection(widget.project),
        const SizedBox(height: 24),
        _buildActionsSection(context, widget.project, widget.viewModel),
      ],
    );
  }

  Widget _buildTopImpactSection(BuildContext context, CompletedProjectDashboardViewModel viewModel) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
              child: _buildMetricCard("Economic Value", "RM ${viewModel.totalEconomicValue.toStringAsFixed(0)}",
                  const Color(0xFF43A047), Icons.attach_money)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildMetricCard("Youth Joined", viewModel.youthParticipated.toString(), const Color(0xFF5C6BC0),
                  Icons.people_alt_outlined)),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _showPopulationDialog(context, viewModel),
              child: _buildMetricCard("Comm. Growth", viewModel.communityGrowth?.toString() ?? "Set",
                  const Color(0xFFFFB74D), Icons.groups_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          FittedBox(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10))),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(Project project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Developed Skills", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD), // Baby Blue
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBDEFB)),
          ),
          child: Column(
            children: project.skills
                .map((skill) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1), // Compact spacing
              child: Row(
                children: [
                  const Icon(Icons.star, size: 12, color: Color(0xFF1976D2)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(skill,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF0D47A1), fontWeight: FontWeight.w500))),
                ],
              ),
            ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectInfoSection(Project project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(project.timeline, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(project.address, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            ],
          ),
          const Divider(height: 24),
          const Text("Project Description", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            project.description,
            maxLines: _isDescriptionExpanded ? null : 2,
            overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          GestureDetector(
            onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isDescriptionExpanded ? "Show Less" : "Read More",
                style: const TextStyle(color: Color(0xFF5C6BC0), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, Project project, CompletedProjectDashboardViewModel viewModel) {
    final plannerViewModel = Provider.of<PlannerViewModel>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailsPage(project: project))),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text("View Project Details", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            final resources = "Project: ${project.title}, Skills: ${project.skills.join(', ')}";
            await plannerViewModel.generatePlan(resources, project.totalBudget);
          },
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF5C6BC0)),
              foregroundColor: const Color(0xFF5C6BC0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text("Generate Next Project", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showPopulationDialog(BuildContext context, CompletedProjectDashboardViewModel viewModel) {
    final initialController = TextEditingController(text: viewModel.initialPopulation?.toString() ?? '');
    final currentController = TextEditingController(text: viewModel.currentPopulation?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Population"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: initialController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Initial Population")),
            TextField(
                controller: currentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Current Population")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                await viewModel.savePopulation(viewModel.project.id!,
                    newInitialPopulation: int.tryParse(initialController.text),
                    newCurrentPopulation: int.tryParse(currentController.text));
                Navigator.pop(ctx);
              },
              child: const Text("Save")),
        ],
      ),
    );
  }
}

// --- REMAINING CLASSES TO ENSURE STATIC ACCESS ---

class CompletedProjectDashboardPage extends StatelessWidget {
  final Project project;
  const CompletedProjectDashboardPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CompletedProjectDashboardViewModel(project: project),
      child: Consumer<CompletedProjectDashboardViewModel>(
        builder: (context, viewModel, _) => Scaffold(
          backgroundColor: const Color(0xFFF5F9FC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
            title: const Text("Project Impact", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: CompletedProjectDashboardContent(viewModel: viewModel, project: viewModel.project),
          ),
        ),
      ),
    );
  }
}

class CompletedProjectDashboardCard extends StatelessWidget {
  final Project project;
  const CompletedProjectDashboardCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CompletedProjectDashboardViewModel(project: project),
      child: Consumer<CompletedProjectDashboardViewModel>(
        builder: (context, viewModel, _) => Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              // FIXED CALL: Accesses static method from the parent class
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CompletedProjectDashboardContent.buildHeader(viewModel.project,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), addShadow: false),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child:
                CompletedProjectDashboardContent(viewModel: viewModel, project: viewModel.project, showHeader: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}