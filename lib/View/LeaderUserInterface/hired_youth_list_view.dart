// lib/View/LeaderUserInterface/hired_youth_list_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewModel/ApplicationViewModel/application_view_model.dart';
import '../../models/ProjectRepository/application_model.dart';
import 'applicant_profile_view.dart'; // Reuse the profile view

class HiredYouthListView extends StatelessWidget {
  final String projectId;
  final String projectTitle;

  const HiredYouthListView({super.key, required this.projectId, required this.projectTitle});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ApplicationViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: const Text("Hired Team"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<Application>>(
        stream: viewModel.getProjectHiredList(projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No team members hired yet.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Team for: $projectTitle",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final app = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(app.applicantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Status: Active Member"),
                        trailing: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApplicantProfileView(
                                  application: app,
                                  showActions: false, // Hide buttons for hired members
                                ),
                              ),
                            );
                          },
                          child: const Text("Profile"),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}