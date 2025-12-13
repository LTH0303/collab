// lib/View/ParticipantViewInterface/participant_job_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewModel/JobViewModule/job_view_model.dart';
import '../../ViewModel/ApplicationViewModel/application_view_model.dart';
import '../../models/project_model.dart';
import 'participant_profile_page.dart';

class ParticipantJobBoard extends StatelessWidget {
  const ParticipantJobBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final jobViewModel = Provider.of<JobViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(Icons.face)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Ahmad bin Ali", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("High Reliability", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                    icon: const Icon(Icons.person_outline),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParticipantProfilePage()))
                )
              ],
            ),
            const SizedBox(height: 24),

            // --- Skills Section ---
            const Text("My Skills", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSkillChip("Agriculture", true),
                _buildSkillChip("Construction", true),
                _buildSkillChip("Electrical", false),
                _buildSkillChip("Manual Labor", false),
              ],
            ),
            const SizedBox(height: 30),

            // --- Available Projects List ---
            const Text("Available Projects", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            StreamBuilder<List<Project>>(
              stream: jobViewModel.activeProjectsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text("No jobs available yet.")));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return JobCard(project: snapshot.data![index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2E5B3E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black54,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// --- Job Card Widget ---
class JobCard extends StatelessWidget {
  final Project project;
  const JobCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final appViewModel = Provider.of<ApplicationViewModel>(context);

    return FutureBuilder<String?>(
      future: appViewModel.getApplicationStatusForProject(project.id!),
      builder: (context, snapshot) {
        String? status = snapshot.data;
        bool isPending = status == 'pending';
        bool isRejected = status == 'rejected';
        bool isApproved = status == 'approved';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(8)),
                    child: const Text("95% Skill Match", style: TextStyle(color: Color(0xFF00695C), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const Icon(Icons.bookmark_border, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Location
              Text(project.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.address.isNotEmpty ? project.address.split(',')[0] : "Kampung Baru",
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info Pills
              Row(
                children: [
                  _buildInfoPill(Icons.access_time, "Duration", project.timeline),
                  const SizedBox(width: 16),
                  _buildInfoPill(Icons.attach_money, "Pay", "RM ${project.totalBudget}"),
                ],
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showProjectDetails(context, project),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text("Details", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (isPending || isRejected || isApproved || appViewModel.isLoading)
                          ? null
                          : () async {
                        bool success = await appViewModel.applyForJob(project);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Sent!")));
                        } else if (appViewModel.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appViewModel.error!), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRejected ? Colors.red : (isApproved ? Colors.green : const Color(0xFF2E5B3E)),
                        disabledBackgroundColor: isRejected ? Colors.red.shade100 : Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: appViewModel.isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                        isRejected ? "Rejected" : (isApproved ? "Hired" : (isPending ? "Pending" : "Apply Now")),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoPill(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: Colors.blue),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  void _showProjectDetails(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, color: Colors.grey[300])),
              const SizedBox(height: 20),
              Text(project.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(project.description, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              const Text("Milestones Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Safely render milestones
              if (project.milestones.isEmpty)
                const Text("No milestones defined.", style: TextStyle(color: Colors.grey))
              else
                ...project.milestones.map((m) => ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                  title: Text(m.taskName),
                  subtitle: Text("Allocated: RM ${m.allocatedBudget}"),
                )),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E5B3E)),
                  child: const Text("Close", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}