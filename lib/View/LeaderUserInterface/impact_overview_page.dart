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

          return Scaffold(
            backgroundColor: const Color(0xFFF5F9FC),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopOverviewCard(viewModel),
                  const SizedBox(height: 24),
                  _buildMonthlyProgressCard(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopOverviewCard(ImpactOverviewViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C6BC0), Color(0xFF26A69A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C6BC0).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Community Impact Overview",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20, // Increased size for better readability
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            // Changed ratio to 1.1 to provide more vertical height for labels
            childAspectRatio: 1.1,
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
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28), // Increased icon size
          const SizedBox(height: 8),
          FittedBox(
            // FittedBox ensures large numbers shrink to fit rather than overflowing
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24, // Significantly larger word size
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2, // Allows two lines if the word is long
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13, // Increased font size for labels
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyProgressCard(ImpactOverviewViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Monthly Progress",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressRow(
            label: "Project Completion",
            percent: viewModel.projectCompletionRateThisMonth,
            color: const Color(0xFF26A69A),
          ),
          const SizedBox(height: 18),
          _buildProgressRow(
            label: "Youth Participation",
            percent: viewModel.youthParticipationThisMonthPercent,
            color: const Color(0xFF5C6BC0),
          ),
          const SizedBox(height: 18),
          _buildProgressRow(
            label: "Community Growth (vs baseline: ${viewModel.communityGrowthLastMonthBaseline})",
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
    final displayPercent = percent.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A4A4A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              "${displayPercent.toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: displayPercent / 100,
            minHeight: 10, // Thicker progress bar for better visibility
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}