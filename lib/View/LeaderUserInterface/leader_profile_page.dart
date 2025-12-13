// lib/View/LeaderUserInterface/leader_profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Authentication/login_page.dart';

class LeaderProfilePage extends StatelessWidget {
  const LeaderProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC), // Light grey-blue bg
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // --- 1. Header Profile ---
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFF33691E), // Dark Green
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              "Dato' Seri Ahmad",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const Text(
              "Village Leader",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFC8E6C9), // Light Green pill
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Kampung Baru",
                style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. Stats Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("12", "Active\nProject", Icons.assignment_outlined, Colors.green),
                _buildStatCard("47", "Completed", Icons.check_circle_outline, Colors.blue),
                _buildStatCard("156", "Youth Hired", Icons.people_outline, Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // --- 3. Contact Info ---
            _buildSectionContainer(
              title: "Contact Information",
              children: [
                _buildListTile(Icons.email_outlined, "Email", "ahmad.leader@gmail.com"),
                const Divider(),
                _buildListTile(Icons.phone_outlined, "Phone", "+60 12-345 6789"),
              ],
            ),
            const SizedBox(height: 16),

            // --- 4. Village Info ---
            _buildSectionContainer(
              title: "Village Information",
              children: [
                _buildListTile(Icons.location_on_outlined, "Village", "Kampung Baru"),
                _buildListTile(Icons.groups_outlined, "Population", "1250 Residents"),
                _buildListTile(Icons.access_time, "Year in Office", "8 Years"),
              ],
            ),
            const SizedBox(height: 30),

            // Logout Button (Styled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                    );
                  }
                },
                child: const Text("Log Out"),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // No shadow to match flat style in screenshot, or very subtle
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.grey[600], size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}