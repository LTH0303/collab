// lib/View/LeaderUserInterface/application_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewModel/ApplicationViewModel/application_view_model.dart';
import '../../models/ProjectRepository/application_model.dart'; // Updated import
import 'applicant_profile_view.dart';

class ApplicationListPage extends StatelessWidget {
  final String? projectId;
  final String? projectTitle;

  const ApplicationListPage({super.key, this.projectId, this.projectTitle});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ApplicationViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(projectTitle != null ? "Applications: $projectTitle" : "Pending Applications"),
      ),
      body: StreamBuilder<List<Application>>(
        stream: projectId != null
            ? viewModel.getProjectApplications(projectId!)
            : viewModel.getLeaderApplications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No pending applications."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final app = snapshot.data![index];
              final state = app.state;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Applicant: ${app.applicantName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("For Project: ${app.projectTitle}", style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ApplicantProfileView(application: app),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            label: const Text("View Profile"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (state.isLeaderActionable)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => viewModel.rejectApplicant(app),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text("Reject"),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => viewModel.approveApplicant(app),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text("Approve"),
                            ),
                          ],
                        )
                      else
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                              state.labelText,
                              style: TextStyle(color: state.displayColor, fontWeight: FontWeight.bold)
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}