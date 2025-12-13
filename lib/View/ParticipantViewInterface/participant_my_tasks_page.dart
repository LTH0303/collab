// lib/View/ParticipantViewInterface/participant_my_tasks_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/DatabaseService/database_service.dart';
import '../../models/project_model.dart';

class ParticipantMyTasksPage extends StatelessWidget {
  const ParticipantMyTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please log in."));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: const Text("My Active Tasks"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // --- Reliability Score Banner ---
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.star, color: Colors.orange, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Reliability Score", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("High (Top 15%)", style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                      const Text("Keep up the great work!", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),

            // --- Active Projects Stream ---
            StreamBuilder<List<Project>>(
              stream: DatabaseService().getParticipantActiveProjects(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.assignment_outlined, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text("No active tasks found.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineProjectCard(context, snapshot.data![index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineProjectCard(BuildContext context, Project project) {
    // Calculate progress for header
    int completed = project.milestones.where((m) => m.isCompleted).length;
    double progress = project.milestones.isEmpty ? 0 : completed / project.milestones.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Project Header ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E5B3E), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  project.address.isNotEmpty ? project.address : "Kampung Location",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${(progress * 100).toInt()}% Complete", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          // --- Milestones Timeline ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Task Milestones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),

                // Render Timeline Items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: project.milestones.length,
                  itemBuilder: (context, index) {
                    final m = project.milestones[index];
                    final isLast = index == project.milestones.length - 1;
                    return _buildTimelineItem(context, project, index, m, isLast);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, Project project, int index, Milestone m, bool isLast) {
    // Determine visuals based on status
    Color bubbleColor;
    Color lineColor;
    Widget statusWidget;
    bool isActionable = false;

    if (m.isCompleted) {
      bubbleColor = const Color(0xFF2E5B3E); // Dark Green
      lineColor = const Color(0xFF2E5B3E);
      statusWidget = const Text("Verified by leader", style: TextStyle(color: Color(0xFF2E5B3E), fontSize: 12, fontWeight: FontWeight.w500));
    } else if (m.isPendingReview) {
      bubbleColor = Colors.orange;
      lineColor = Colors.grey.shade300;
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4)),
        child: const Text("Under Review", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    } else if (m.isOpen) {
      bubbleColor = const Color(0xFF2962FF); // Blue
      lineColor = Colors.grey.shade300;
      isActionable = true;
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFF2E5B3E), borderRadius: BorderRadius.circular(12)),
        child: const Text("Upload Photo Proof", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    } else if (m.isRejected) {
      bubbleColor = Colors.red;
      lineColor = Colors.grey.shade300;
      isActionable = true;
      statusWidget = const Text("Rejected - Try Again", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold));
    } else {
      bubbleColor = Colors.grey.shade300; // Locked
      lineColor = Colors.grey.shade300;
      statusWidget = const SizedBox(); // Empty
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Timeline Line & Bubble ---
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    shape: BoxShape.circle,
                  ),
                  child: m.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),

          // --- Content Card ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: GestureDetector(
                onTap: isActionable ? () => _showSubmissionDialog(context, project, index) : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100], // Light grey bg
                    borderRadius: BorderRadius.circular(12),
                    border: isActionable ? Border.all(color: bubbleColor.withOpacity(0.5)) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.taskName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: m.isLocked ? Colors.grey : Colors.black87
                        ),
                      ),
                      const SizedBox(height: 4),
                      statusWidget,
                      if (m.isRejected && m.rejectionReason != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("Note: ${m.rejectionReason}", style: const TextStyle(color: Colors.red, fontSize: 11, fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmissionDialog(BuildContext context, Project project, int index) {
    final expenseController = TextEditingController();
    final milestone = project.milestones[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Submit: ${milestone.taskName}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: const Text("Upload a clear photo of your work and enter the exact amount spent from the budget.", style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 16),

            // Mock Photo Upload
            const Text("Proof of Work (Photo)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt, color: Colors.grey),
                  Text("Tap to upload", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text("Expenses Incurred (RM)", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: expenseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "e.g., 50.00",
                prefixText: "RM ",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (expenseController.text.isEmpty) return;

              Navigator.pop(context); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submitting...")));

              try {
                // Mock Photo URL for now
                await DatabaseService().submitMilestone(project.id!, index, expenseController.text, "https://mock.url/photo.jpg");
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submitted successfully!"), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Submit for Review"),
          ),
        ],
      ),
    );
  }
}