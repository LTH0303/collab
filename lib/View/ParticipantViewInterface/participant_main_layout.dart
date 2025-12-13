// lib/View/ParticipantViewInterface/participant_main_layout.dart

import 'package:flutter/material.dart';
import 'participant_job_list_screen.dart';
import 'participant_my_tasks_page.dart'; // Import the new page

class ParticipantMainLayout extends StatefulWidget {
  const ParticipantMainLayout({super.key});

  @override
  State<ParticipantMainLayout> createState() => _ParticipantMainLayoutState();
}

class _ParticipantMainLayoutState extends State<ParticipantMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ParticipantJobBoard(),
    const ParticipantMyTasksPage(), // Use the actual page now
    const Center(child: Text("Community (Coming Soon)")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF2E5B3E),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: "Find Jobs"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in), label: "My Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "Community"),
        ],
      ),
    );
  }
}