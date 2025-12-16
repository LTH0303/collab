import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ViewModel/ImpactOverviewViewModel/impact_overview_view_model.dart';

class ImpactOverviewPage extends StatelessWidget {
  const ImpactOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ImpactOverviewViewModel(),
      child: Consumer<ImpactOverviewViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.error != null) {
            return Center(child: Text(viewModel.error!));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopOverviewCard(viewModel),
                const SizedBox(height: 20),
                _buildMonthlyProgressCard(viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopOverviewCard(ImpactOverviewViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C6BC0), Color(0xFF26A69A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Community Impact Overview",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _buildMetricTile(
                icon: Icons.groups,
                title: "Youth Employed",
                value: viewModel.totalYouthParticipated.toString(),
              ),
              _buildMetricTile(
                icon: Icons.work_outline,
                title: "Active Projects",
                value: viewModel.activeProjectsCount.toString(),
              ),
              _buildMetricTile(
                icon: Icons.attach_money,
                title: "Economic Value",
                value: "RM ${viewModel.totalEconomicValue.toStringAsFixed(0)}",
              ),
              _buildMetricTile(
                icon: Icons.check_circle_outline,
                title: "Completed Projects",
                value: viewModel.completedProjectsCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyProgressCard(ImpactOverviewViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          const Text(
            "Monthly Progress",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressRow(
            label: "Project Completion",
            percent: viewModel.projectCompletionRateThisMonth,
            color: const Color(0xFF26A69A),
          ),
          const SizedBox(height: 12),
          _buildProgressRow(
            label: "Youth Participation",
            percent: viewModel.youthParticipationThisMonthPercent,
            color: const Color(0xFF5C6BC0),
          ),
          const SizedBox(height: 12),
          _buildProgressRow(
            label:
            "Community Growth (vs last month: ${viewModel.communityGrowthLastMonthBaseline})",
            percent: viewModel.communityGrowthThisMonthPercent,
            color: const Color(0xFF8E24AA),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required double percent,
    required Color color,
  }) {
    final displayPercent = percent.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            Text(
              "${displayPercent.toStringAsFixed(0)}%",
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: displayPercent / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}


