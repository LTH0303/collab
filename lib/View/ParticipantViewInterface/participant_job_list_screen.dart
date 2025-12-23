// lib/View/ParticipantViewInterface/participant_job_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ViewModel/JobViewModule/job_view_model.dart';
import '../../ViewModel/ApplicationViewModel/application_view_model.dart';
import '../../models/ProjectRepository/project_model.dart';
import '../../models/ProjectRepository/application_state.dart';
import '../../models/DatabaseService/database_service.dart';
import 'participant_profile_page.dart';

class ParticipantJobBoard extends StatefulWidget {
  const ParticipantJobBoard({super.key});

  @override
  State<ParticipantJobBoard> createState() => _ParticipantJobBoardState();
}

class _ParticipantJobBoardState extends State<ParticipantJobBoard> {
  // 0: All Jobs, 1: Saved Jobs
  int _selectedViewIndex = 0;

  @override
  Widget build(BuildContext context) {
    final jobViewModel = Provider.of<JobViewModel>(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Center(child: Text("Please Login"));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      // Use StreamBuilder to listen to Profile Changes (Name/Skills/Saved Jobs)
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: DatabaseService().streamUserProfile(user.uid),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Default data if new user
          final userData = profileSnapshot.data ?? {};
          final userName = userData['name'] ?? 'Participant';
          final userSkills = List<String>.from(userData['skills'] ?? []);
          final reliabilityScore = userData['reliability_score'] ?? 100;
          final savedProjects = List<String>.from(userData['saved_projects'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Dynamic Header (Synced with Profile) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                          child: const CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(Icons.face)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("Reliability: $reliabilityScore", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

                // --- 2. Dynamic Skills Section ---
                const Text("My Skills", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (userSkills.isEmpty)
                  const Text("No skills added yet. Edit Profile to add skills.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: userSkills.map((s) => _buildSkillChip(s)).toList(),
                  ),

                const SizedBox(height: 30),

                // --- 3. View Switcher (All Jobs / Saved) ---
                Row(
                  children: [
                    _buildTabButton("All Jobs", 0),
                    const SizedBox(width: 12),
                    _buildTabButton("Saved", 1),
                  ],
                ),
                const SizedBox(height: 16),

                // --- 4. Projects List with Match Logic ---
                StreamBuilder<List<Project>>(
                  stream: jobViewModel.activeProjectsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text("No jobs available yet.")));
                    }

                    // Filter Logic based on selected Tab
                    List<Project> displayProjects = snapshot.data!;
                    if (_selectedViewIndex == 1) {
                      displayProjects = displayProjects.where((p) => savedProjects.contains(p.id)).toList();
                    }

                    if (displayProjects.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text(
                            _selectedViewIndex == 1 ? "No saved jobs yet." : "No jobs matching criteria.",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayProjects.length,
                      itemBuilder: (context, index) {
                        final project = displayProjects[index];
                        final isSaved = savedProjects.contains(project.id);

                        return JobCard(
                          project: project,
                          userSkills: userSkills, // Pass skills for matching
                          isSaved: isSaved, // Pass saved status
                          onToggleSave: () {
                            jobViewModel.toggleSavedJob(project.id!, isSaved);
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    bool isSelected = _selectedViewIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedViewIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E88E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF1E88E5) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E5B3E), // Selected Green
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// --- Job Card Widget ---
class JobCard extends StatelessWidget {
  final Project project;
  final List<String> userSkills;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const JobCard({
    super.key,
    required this.project,
    required this.userSkills,
    required this.isSaved,
    required this.onToggleSave,
  });

  int _calculateMatchPercentage() {
    if (project.skills.isEmpty) return 100;
    if (userSkills.isEmpty) return 0;

    final pSkills = project.skills.map((s) => s.toLowerCase().trim()).toList();
    final uSkills = userSkills.map((s) => s.toLowerCase().trim()).toSet();

    int matches = 0;

    for (var reqSkill in pSkills) {
      if (uSkills.contains(reqSkill)) {
        matches++;
        continue;
      }
      bool partialMatch = uSkills.any((uSkill) => uSkill.contains(reqSkill) || reqSkill.contains(uSkill));
      if (partialMatch) {
        matches++;
      }
    }

    double percent = (matches / pSkills.length) * 100;
    return percent.clamp(0, 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final appViewModel = Provider.of<ApplicationViewModel>(context);
    final matchPercent = _calculateMatchPercentage();

    return FutureBuilder<String?>(
      future: appViewModel.getApplicationStatusForProject(project.id!),
      builder: (context, snapshot) {
        String statusString = snapshot.data ?? 'none';
        ApplicationState state = ApplicationState.fromString(statusString);
        bool isPending = statusString == 'pending';
        bool isWithdrawn = statusString == 'withdrawn';

        // Allow apply if never applied (null) OR withdrawn
        bool canApply = snapshot.data == null || isWithdrawn;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: matchPercent > 70 ? const Color(0xFFE0F2F1) : (matchPercent > 40 ? Colors.orange[50] : Colors.red[50]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$matchPercent% Skill Match",
                      style: TextStyle(
                          color: matchPercent > 70 ? const Color(0xFF00695C) : (matchPercent > 40 ? Colors.orange[800] : Colors.red[800]),
                          fontSize: 10,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onToggleSave,
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

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

              if (project.skills.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: project.skills.map((s) {
                      String req = s.toLowerCase().trim();
                      bool hasSkill = userSkills.any((us) {
                        String userS = us.toLowerCase().trim();
                        return userS == req || userS.contains(req) || req.contains(userS);
                      });

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: hasSkill ? Colors.green[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: hasSkill ? Colors.green.shade200 : Colors.grey.shade300),
                        ),
                        child: Text(s, style: TextStyle(fontSize: 10, color: hasSkill ? Colors.green[800] : Colors.grey[600])),
                      );
                    }).toList(),
                  ),
                ),

              Row(
                children: [
                  _buildInfoPill(Icons.access_time, "Duration", project.timeline),
                  const SizedBox(width: 16),
                  _buildInfoPill(Icons.attach_money, "Value", "RM ${project.totalBudget}"),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showProjectDetails(context, project),
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text("Details", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // APPLY / WITHDRAW / RE-APPLY BUTTON LOGIC
                  Expanded(
                    child: isPending
                        ? OutlinedButton(
                      onPressed: () async {
                        bool success = await appViewModel.withdrawApplication(project.id!);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Withdrawn")));
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Withdraw"),
                    )
                        : ElevatedButton(
                      onPressed: (canApply && !appViewModel.isLoading)
                          ? () async {
                        bool success = await appViewModel.applyForJob(project);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Sent!")));
                        } else if (appViewModel.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(appViewModel.error!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canApply ? const Color(0xFF2E5B3E) : state.displayColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: appViewModel.isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                          canApply
                              ? (isWithdrawn ? "Re-apply" : "Apply Now")
                              : state.participantButtonText,
                          style: const TextStyle(color: Colors.white)
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