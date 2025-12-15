import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ProjectRepository/project_model.dart';
import '../../ViewModel/ProjectDetailsViewModel/completed_project_view_model.dart';
import '../../ViewModel/PlannerViewModel/planner_view_model.dart';
import 'project_details_page.dart';

/// --- Shared Content Widget (used by both Page and Card) ---
class CompletedProjectDashboardContent extends StatelessWidget {
  final CompletedProjectDashboardViewModel viewModel;
  final Project project;
  final bool showHeader;

  const CompletedProjectDashboardContent({
    super.key,
    required this.viewModel,
    required this.project,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          buildHeader(
            project,
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
        _buildTopImpactSection(context, viewModel),
        const SizedBox(height: 16),
        _buildProjectDetailsSection(project),
        const SizedBox(height: 16),
        _buildActionsSection(context, project, viewModel),
      ],
    );
  }

  /// --- Header ---
  /// Shared header builder (used by page and card)
  static Widget buildHeader(
      Project project, {
        BorderRadius? borderRadius,
        bool addShadow = true,
      }) {
    final completedCount = project.milestones.where((m) => m.isCompleted).length;
    final totalCount = project.milestones.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C6BC0), Color(0xFF8E24AA)],
        ),
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
              Row(
                children: [
                  _buildChip(label: "Completed", color: Colors.white24, textColor: Colors.white),
                  const SizedBox(width: 8),
                  _buildChip(label: "Success", color: Colors.white24, textColor: Colors.white),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "$completedCount/$totalCount milestones",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildChip({required String label, required Color color, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  /// --- Top Impact Metrics ---
  Widget _buildTopImpactSection(BuildContext context, CompletedProjectDashboardViewModel viewModel) {
    final communityGrowth = viewModel.communityGrowth;
    final hasPopulationData =
        viewModel.initialPopulation != null && viewModel.currentPopulation != null;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: "Economic Value",
            value: "RM ${viewModel.totalEconomicValue.toStringAsFixed(0)}",
            subtitle: "Total verified incentives\nclaimed by youths",
            color: const Color(0xFF43A047),
            icon: Icons.attach_money,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: "Youth Participated",
            value: viewModel.youthParticipated.toString(),
            subtitle: "Total youths who joined\nthis project",
            color: const Color(0xFF5C6BC0),
            icon: Icons.people_alt_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (viewModel.project.id != null) {
                _showPopulationDialog(context, viewModel);
              }
            },
            child: _buildMetricCard(
              title: "Community Growth",
              value: hasPopulationData ? "${communityGrowth ?? 0}" : "Set Population",
              subtitle: hasPopulationData
                  ? "Current vs starting\nvillage population"
                  : "Tap to enter initial &\ncurrent population",
              color: const Color(0xFFFFB74D),
              icon: Icons.groups_outlined,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// --- Project Details Section ---
  Widget _buildProjectDetailsSection(Project project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Icon(Icons.schedule, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                project.timeline,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  project.address,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: project.skills
                .map(
                  (skill) => Chip(
                label: Text(skill, style: const TextStyle(fontSize: 10)),
                backgroundColor: const Color(0xFFE3F2FD),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
            )
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            "Project Description",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            project.description,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  /// --- Actions Section ---
  Widget _buildActionsSection(BuildContext context, Project project, CompletedProjectDashboardViewModel viewModel) {
    final plannerViewModel = Provider.of<PlannerViewModel>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectDetailsPage(project: project),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "View Project Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              final resources = StringBuffer()
                ..writeln("Existing project: ${project.title}")
                ..writeln("Key skills developed: ${project.skills.join(', ')}")
                ..writeln("Address: ${project.address}")
                ..writeln("Proven community assets: ${project.startingResources.join(', ')}");

              await plannerViewModel.generatePlan(
                resources.toString(),
                project.totalBudget,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("AI has generated a new proposal based on this project's impact."),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF5C6BC0)),
              foregroundColor: const Color(0xFF5C6BC0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Generate Next Project",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  /// --- Population Dialog ---
  void _showPopulationDialog(BuildContext context, CompletedProjectDashboardViewModel viewModel) {
    final initialController = TextEditingController(
      text: viewModel.initialPopulation?.toString() ?? '',
    );
    final currentController = TextEditingController(
      text: viewModel.currentPopulation?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Update Community Population"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Tell us how your village population changed from the start of this project.",
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: initialController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Initial population at project start",
                  prefixIcon: Icon(Icons.group_outlined),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: currentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Current village population",
                  prefixIcon: Icon(Icons.group),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final initial = int.tryParse(initialController.text);
                final current = int.tryParse(currentController.text);

                await viewModel.savePopulation(
                  viewModel.project.id!,
                  newInitialPopulation: initial,
                  newCurrentPopulation: current,
                );

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}

/// --- Completed Project Dashboard Page ---
class CompletedProjectDashboardPage extends StatelessWidget {
  final Project project;

  const CompletedProjectDashboardPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CompletedProjectDashboardViewModel(project: project),
      child: Consumer<CompletedProjectDashboardViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F9FC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                "Completed Project Impact",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: CompletedProjectDashboardContent(
                viewModel: viewModel,
                project: viewModel.project,
                showHeader: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// --- Completed Project Card (for list) ---
class CompletedProjectDashboardCard extends StatelessWidget {
  final Project project;

  const CompletedProjectDashboardCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CompletedProjectDashboardViewModel(project: project),
      child: Consumer<CompletedProjectDashboardViewModel>(
        builder: (context, viewModel, _) {
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
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
                // Full-width header on top, like the Active card style
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CompletedProjectDashboardContent.buildHeader(
                    viewModel.project,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    addShadow: false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CompletedProjectDashboardContent(
                    viewModel: viewModel,
                    project: viewModel.project,
                    showHeader: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
