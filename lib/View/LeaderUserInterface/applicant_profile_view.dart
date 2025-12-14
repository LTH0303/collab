// lib/View/LeaderUserInterface/applicant_profile_view.dart

import 'package:flutter/material.dart';
import '../../models/ProjectRepository/application_model.dart'; // Updated import
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: DatabaseService().getUserProfile(application.applicantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {
            'email': 'Loading...',
            'skills': ['General Labor'],
            'reliability': 'New',
            'location': 'Unknown'
          };

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
                  application.applicantName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Project: ${application.projectTitle}",
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(Icons.star, "Reliability", "High"),
                    _buildStatItem(Icons.work, "Completed", "5 Jobs"),
                    _buildStatItem(Icons.location_on, "Village", "Kg. Baru"),
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (data['skills'] as List<dynamic>? ?? ['Hardworking']).map((skill) {
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
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.phone_outlined, color: Colors.grey),
                        title: Text("+60 12-345 6789"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                onPressed: () {
                  appViewModel.rejectApplicant(application);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Rejected")));
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
                onPressed: () {
                  appViewModel.approveApplicant(application);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Applicant Hired!")));
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

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}