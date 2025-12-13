// lib/View/ParticipantViewInterface/active_project_details.dart

import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import 'package:provider/provider.dart';
import '../../ViewModel/JobViewModule/job_view_model.dart';

class ActiveProjectDetails extends StatefulWidget {
  final Project project;
  const ActiveProjectDetails({super.key, required this.project});

  @override
  State<ActiveProjectDetails> createState() => _ActiveProjectDetailsState();
}

class _ActiveProjectDetailsState extends State<ActiveProjectDetails> {

  void _showSubmitDialog(BuildContext context, int index) {
    final expenseController = TextEditingController();
    final milestone = widget.project.milestones[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Submit: ${milestone.taskName}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Budget Limit: RM ${milestone.allocatedBudget}",
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("Proof of Work:", style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              height: 80,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.camera_alt, color: Colors.grey)),
            ),
            const SizedBox(height: 16),
            const Text("Total Expenses Incurred:", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: expenseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter amount (RM)...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              // 1. Get amount
              String amount = expenseController.text;
              if (amount.isEmpty) return;

              // 2. Call ViewModel to submit
              Provider.of<JobViewModel>(context, listen: false).submitMilestoneExpense(
                  widget.project,
                  index,
                  amount
              );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submitted for review!")));
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Summary
            Text("Total Grant: RM ${widget.project.totalBudget}",
                style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            const Text("Milestones Progress", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.project.milestones.length,
              itemBuilder: (context, index) {
                final m = widget.project.milestones[index];

                // Logic: Locked if previous is not complete
                bool isLocked = index > 0 && !widget.project.milestones[index-1].isCompleted;

                return Card(
                  color: isLocked ? Colors.grey[100] : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: m.isCompleted ? Colors.green : (isLocked ? Colors.grey : Colors.blue),
                      child: Icon(m.isCompleted ? Icons.check : Icons.work, color: Colors.white, size: 16),
                    ),
                    title: Text(m.taskName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Allocated: RM ${m.allocatedBudget}"),
                        if (m.isCompleted)
                          Text("Claimed: RM ${m.expenseClaimed}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: m.isCompleted
                        ? const Icon(Icons.verified, color: Colors.green)
                        : (isLocked
                        ? const Icon(Icons.lock, color: Colors.grey)
                        : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      onPressed: () => _showSubmitDialog(context, index),
                      child: const Text("Submit"),
                    )
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}