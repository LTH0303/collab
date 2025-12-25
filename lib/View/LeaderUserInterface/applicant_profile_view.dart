// lib/View/LeaderUserInterface/applicant_profile_view.dart

import 'package:flutter/material.dart';
import '../../models/ProjectRepository/application_model.dart';
import '../../models/ProjectRepository/project_model.dart'; // Added for Project model
import '../../models/DatabaseService/database_service.dart';
import '../../ViewModel/ApplicationViewModel/application_view_model.dart';
import 'package:provider/provider.dart';

class ApplicantProfileView extends StatelessWidget {
  final Application application;
  final bool showActions;

  const ApplicantProfileView({
    super.key,
    required this.application,
    this.showActions = true,
  });

  // Helper to determine reliability label and color
  Map<String, dynamic> _getReliabilityInfo(int score) {
    if (score >= 80) {
      return {'label': 'High', 'color': Colors.green};
    } else if (score >= 50) {
      return {'label': 'Medium', 'color': Colors.orange};
    } else {
      return {'label': 'Low', 'color': Colors.red};
    }
  }

  @override
  Widget build(BuildContext context) {
    final appViewModel = Provider.of<ApplicationViewModel>(context, listen: false);
    final currentState = application.state;
    final bool canAct = showActions && currentState.isLeaderActionable;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: Text(showActions ? "Applicant Profile" : "Team Member Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: currentState.displayColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: currentState.displayColor),
            ),
            child: Text(
              currentState.labelText,
              style: TextStyle(
                  color: currentState.displayColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12
              ),
            ),
          )
        ],
      ),
      // 1. Stream User Profile for Real-Time Reliability & Info
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: DatabaseService().streamUserProfile(application.applicantId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = userSnapshot.data ?? {
            'name': application.applicantName, // Fallback to application data
            'email': 'No Email',
            'skills': [],
            'reliability_score': 100, // Default
            'village': 'Unknown'
          };

          final int reliabilityScore = data['reliability_score'] ?? 100;
          final reliabilityInfo = _getReliabilityInfo(reliabilityScore);

          // 2. Stream Projects to Calculate Completed Jobs
          return StreamBuilder<List<Project>>(
            stream: DatabaseService().getParticipantAllProjects(application.applicantId),
            builder: (context, projectSnapshot) {
              int completedJobsCount = 0;
              if (projectSnapshot.hasData) {
                // Count projects where status is 'completed'
                completedJobsCount = projectSnapshot.data!
                    .where((p) => p.status == 'completed')
                    .length;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFF1E88E5),
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['name'] ?? application.applicantName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Applying for: ${application.projectTitle}",
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          Icons.star,
                          "Reliability",
                          "${reliabilityInfo['label']} ($reliabilityScore)",
                          iconColor: reliabilityInfo['color'],
                        ),
                        _buildStatItem(
                          Icons.work,
                          "Completed",
                          "$completedJobsCount Jobs",
                          iconColor: Colors.blue,
                        ),
                        _buildStatItem(
                          Icons.location_on,
                          "Village",
                          data['village'] ?? "Kg. Baru",
                          iconColor: Colors.redAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Skills
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Skills & Expertise", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          if ((data['skills'] as List<dynamic>? ?? []).isEmpty)
                            const Text("No skills listed.", style: TextStyle(color: Colors.grey))
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (data['skills'] as List<dynamic>).map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20)),
                                  child: Text(skill.toString(), style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 12)),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Contact
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Contact Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.email_outlined, color: Colors.grey),
                            title: Text(data['email'] ?? "No Email"),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.phone_outlined, color: Colors.grey),
                            title: Text(data['phone'] ?? "No Phone"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: canAct
          ? Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                // UPDATED: Made async to ensure action completes before closing
                onPressed: () async {
                  await appViewModel.rejectApplicant(application);

                  // Check if context is still valid before using it
                  if (context.mounted) {
                    Navigator.pop(context); // Close the command window
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Application Rejected"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text("Reject"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                // UPDATED: Made async to ensure action completes before closing
                onPressed: () async {
                  await appViewModel.approveApplicant(application);

                  // Check if context is still valid before using it
                  if (context.mounted) {
                    Navigator.pop(context); // Close the command window
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Applicant Hired!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Approve & Hire", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      )
          : null,
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {Color iconColor = Colors.orange}) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}