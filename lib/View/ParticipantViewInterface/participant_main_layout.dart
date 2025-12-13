import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for Logout
import '../Authentication/login_page.dart'; // Import for Navigation
import 'participant_job_list_screen.dart'; // Job Board

class ParticipantMainLayout extends StatefulWidget {
  const ParticipantMainLayout({super.key});

  @override
  State<ParticipantMainLayout> createState() => _ParticipantMainLayoutState();
}

class _ParticipantMainLayoutState extends State<ParticipantMainLayout> {
  int _currentIndex = 0;

  // Define the pages for the bottom navigation
  final List<Widget> _children = [
    // 1. Job Board (From existing file)
    ParticipantJobBoard(),

    // 2. Applications (Placeholder)
    const Scaffold(body: Center(child: Text("My Applications (Coming Soon)"))),

    // 3. Profile (New Implementation based on Figma)
    const ParticipantProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We remove the AppBar here so each child page can have its own specific AppBar
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onTabTapped,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1E88E5), // Participant Blue
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Applications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NEW CLASS: ParticipantProfilePage (With Logout Button)
// ---------------------------------------------------------------------------
class ParticipantProfilePage extends StatelessWidget {
  const ParticipantProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC), // Light blue-grey background
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hidden back arrow for Tab view
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () {}, // Edit profile logic
          ),
          // -----------------------------------------------------------
          // UPDATED: Added Logout Button Logic here
          // -----------------------------------------------------------
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                // Navigate back to Login Page and clear the navigation stack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- 1. Profile Header ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF1E88E5), // Blue
                    child: Icon(Icons.face, size: 45, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ahmad bin Ali",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "22 years old • Kampung Baru",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), // Light Yellow pill
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                        SizedBox(width: 6),
                        Text(
                          "High Reliability",
                          style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 2. Stats Row ---
            Row(
              children: [
                _buildStatCard("34", "Tasks Done", Icons.check_circle_outline, const Color(0xFFE3F2FD), const Color(0xFF1E88E5)),
                const SizedBox(width: 12),
                _buildStatCard("3", "Active", Icons.description_outlined, const Color(0xFFE8F5E9), const Color(0xFF43A047)),
                const SizedBox(width: 12),
                _buildStatCard("RM4850", "Earned", Icons.monetization_on_outlined, const Color(0xFFFFF3E0), const Color(0xFFFF9800)),
              ],
            ),

            const SizedBox(height: 24),

            // --- 3. Contact Information ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Contact Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(Icons.email_outlined, "Email", "ahmad.youth@kampungbaru.my"),
                  const Divider(height: 1, indent: 60),
                  _buildInfoTile(Icons.phone_outlined, "Phone", "+60 19-876 5432"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 4. My Skills ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("My Skills", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildSkillChip("Agriculture"),
                  _buildSkillChip("Construction"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String count, String label, IconData icon, Color bg, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.grey[600], size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Light blue chip
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}