// lib/View/LeaderUserInterface/leader_profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/DatabaseService/database_service.dart';
import '../Authentication/login_page.dart';

// --- MODEL ---
class LeaderProfile {
  String name;
  String village;
  String email;
  String phone;
  String population;
  String yearsInOffice;

  LeaderProfile({
    required this.name,
    required this.village,
    required this.email,
    required this.phone,
    required this.population,
    required this.yearsInOffice,
  });

  factory LeaderProfile.fromMap(Map<String, dynamic> data) {
    return LeaderProfile(
      name: data['name'] ?? "Dato' Seri Ahmad",
      village: data['village'] ?? "Kampung Baru",
      email: data['email'] ?? "ahmad.leader@gmail.com",
      phone: data['phone'] ?? "+60 12-345 6789",
      population: data['population'] ?? "1250",
      yearsInOffice: data['years_in_office'] ?? "8",
    );
  }
}

// --- MAIN PAGE ---
class LeaderProfilePage extends StatelessWidget {
  const LeaderProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please Login")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC), // Light grey-blue bg
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Edit Button (Only shows if data loads)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();

              final profile = LeaderProfile.fromMap(snapshot.data!.data() as Map<String, dynamic>);

              return IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditLeaderProfilePage(currentProfile: profile, userId: user.uid),
                    ),
                  );
                },
              );
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = (snapshot.hasData && snapshot.data!.exists)
              ? snapshot.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          final profile = LeaderProfile.fromMap(data);

          return SingleChildScrollView(
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
                Text(
                  profile.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
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
                  child: Text(
                    profile.village,
                    style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30),

                // --- 2. Stats Row ---
                // (Static for now, could be dynamic later)
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
                    _buildListTile(Icons.email_outlined, "Email", profile.email),
                    const Divider(),
                    _buildListTile(Icons.phone_outlined, "Phone", profile.phone),
                  ],
                ),
                const SizedBox(height: 16),

                // --- 4. Village Info ---
                _buildSectionContainer(
                  title: "Village Information",
                  children: [
                    _buildListTile(Icons.location_on_outlined, "Village", profile.village),
                    _buildListTile(Icons.groups_outlined, "Population", "${profile.population} Residents"),
                    _buildListTile(Icons.access_time, "Year in Office", "${profile.yearsInOffice} Years"),
                  ],
                ),
                const SizedBox(height: 30),

                // Logout Button
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
          );
        },
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

// --- EDIT PAGE ---
class EditLeaderProfilePage extends StatefulWidget {
  final LeaderProfile currentProfile;
  final String userId;

  const EditLeaderProfilePage({super.key, required this.currentProfile, required this.userId});

  @override
  State<EditLeaderProfilePage> createState() => _EditLeaderProfilePageState();
}

class _EditLeaderProfilePageState extends State<EditLeaderProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _villageController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _populationController;
  late TextEditingController _yearsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile.name);
    _villageController = TextEditingController(text: widget.currentProfile.village);
    _emailController = TextEditingController(text: widget.currentProfile.email);
    _phoneController = TextEditingController(text: widget.currentProfile.phone);
    _populationController = TextEditingController(text: widget.currentProfile.population);
    _yearsController = TextEditingController(text: widget.currentProfile.yearsInOffice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final messenger = ScaffoldMessenger.of(context);

                Map<String, dynamic> data = {
                  'name': _nameController.text,
                  'village': _villageController.text,
                  'email': _emailController.text,
                  'phone': _phoneController.text,
                  'population': _populationController.text,
                  'years_in_office': _yearsController.text,
                };

                await DatabaseService().updateUserProfile(widget.userId, data);

                messenger.showSnackBar(const SnackBar(content: Text("Profile Updated!")));
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Personal Details"),
              _buildTextField("Full Name", _nameController, Icons.person),
              _buildTextField("Village Name", _villageController, Icons.location_city),

              const SizedBox(height: 24),
              _buildSectionTitle("Contact Info"),
              _buildTextField("Email", _emailController, Icons.email),
              _buildTextField("Phone", _phoneController, Icons.phone),

              const SizedBox(height: 24),
              _buildSectionTitle("Village Statistics"),
              _buildTextField("Population (Count)", _populationController, Icons.groups),
              _buildTextField("Years in Office", _yearsController, Icons.access_time),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) => value!.isEmpty ? "Required" : null,
      ),
    );
  }
}