import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- VIEW IMPORTS ---
// Ensure these paths match your project structure
import 'participant_job_list_screen.dart'; // Tab 1: Jobs (Contains Top Bar Profile Access)
import 'participant_my_tasks_page.dart';   // Tab 2: My Tasks
import '../CommunityInterface/community_hub_page.dart'; // Tab 3: Community

class ParticipantMainLayout extends StatefulWidget {
  const ParticipantMainLayout({super.key});

  @override
  State<ParticipantMainLayout> createState() => _ParticipantMainLayoutState();
}

class _ParticipantMainLayoutState extends State<ParticipantMainLayout> {
  int _currentIndex = 0;

  // Define the pages for the bottom navigation
  // Note: The Profile button is located inside the header of ParticipantJobBoard
  final List<Widget> _pages = [
    const ParticipantJobBoard(),      // Index 0: Job Board
    const ParticipantMyTasksPage(),   // Index 1: My Tasks (Timeline & Status)
    const CommunityHubPage(),         // Index 2: Community Hub (Forum)
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the state of each tab (scrolling position, inputs, etc.)
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onTabTapped,
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E88E5), // Youth Blue theme
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'My Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Community',
          ),
        ],
      ),
    );
  }
}