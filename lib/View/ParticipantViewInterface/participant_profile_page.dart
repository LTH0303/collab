// lib/View/ParticipantViewInterface/participant_profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/DatabaseService/database_service.dart';
import '../../models/ProjectRepository/project_model.dart';
import '../Authentication/login_page.dart';

// ... (UserProfile class remains same)
class UserProfile {
  String name;
  String location;
  String email;
  String phone;
  List<String> skills;
  int reliabilityScore;

  UserProfile({
    required this.name,
    required this.location,
    required this.email,
    required this.phone,
    required this.skills,
    required this.reliabilityScore,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      name: data['name'] ?? 'Participant',
      location: data['village'] ?? 'Unknown Location',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '+60 12-345 6789',
      skills: List<String>.from(data['skills'] ?? []),
      reliabilityScore: data['reliability_score'] ?? 100,
    );
  }
}

// ... (Strategy classes remain same)
abstract class ReliabilityStrategy {
  String get label;
  Color get primaryColor;
  Color get backgroundColor;
  Color get barColor;
  IconData get icon;
}

class HighReliabilityStrategy implements ReliabilityStrategy {
  @override
  String get label => "High Reliability";
  @override
  Color get primaryColor => const Color(0xFF2E7D32);
  @override
  Color get backgroundColor => const Color(0xFFE8F5E9);
  @override
  Color get barColor => const Color(0xFF43A047);
  @override
  IconData get icon => Icons.verified_user;
}

class MediumReliabilityStrategy implements ReliabilityStrategy {
  @override
  String get label => "Medium Reliability";
  @override
  Color get primaryColor => const Color(0xFFFFA000);
  @override
  Color get backgroundColor => const Color(0xFFFFF8E1);
  @override
  Color get barColor => const Color(0xFFFFC107);
  @override
  IconData get icon => Icons.star_half;
}

class LowReliabilityStrategy implements ReliabilityStrategy {
  @override
  String get label => "Needs Improvement";
  @override
  Color get primaryColor => const Color(0xFFC62828);
  @override
  Color get backgroundColor => const Color(0xFFFFEBEE);
  @override
  Color get barColor => const Color(0xFFE57373);
  @override
  IconData get icon => Icons.warning_amber_rounded;
}

// ... (ParticipantProfilePage)
class ParticipantProfilePage extends StatelessWidget {
  const ParticipantProfilePage({super.key});

  ReliabilityStrategy _getReliabilityStrategy(int score) {
    if (score >= 80) return HighReliabilityStrategy();
    if (score >= 50) return MediumReliabilityStrategy();
    return LowReliabilityStrategy();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Please login first"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox();
              }
              final userProfile = UserProfile.fromMap(snapshot.data!.data() as Map<String, dynamic>);

              return IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        currentProfile: userProfile,
                        userId: user.uid,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text("User data not found"));
          }

          final userProfile = UserProfile.fromMap(userSnapshot.data!.data() as Map<String, dynamic>);
          final strategy = _getReliabilityStrategy(userProfile.reliabilityScore);

          return StreamBuilder<List<Project>>(
            stream: DatabaseService().getParticipantAllProjects(user.uid),
            builder: (context, projectSnapshot) {
              int activeJobs = 0;
              int completedJobs = 0; // NEW: Track completed jobs

              if (projectSnapshot.hasData) {
                final projects = projectSnapshot.data!;
                // Count Active Jobs
                activeJobs = projects.where((p) => p.status == 'active').length;
                // Count Completed Jobs
                completedJobs = projects.where((p) => p.status == 'completed').length;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 45,
                      backgroundColor: Color(0xFF1E88E5),
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userProfile.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(strategy.icon, color: strategy.primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Text(strategy.label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userProfile.location,
                        style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- REAL STAT CARDS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Even spacing
                      children: [
                        _buildStatCard(activeJobs.toString(), "Active\nJob", Icons.work_outline, Colors.blue),
                        // NEW: Completed Jobs Card
                        _buildStatCard(completedJobs.toString(), "Completed", Icons.check_circle_outline, Colors.green),
                        _buildStatCard("${userProfile.skills.length}", "Skills", Icons.school_outlined, Colors.orange),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Reliability Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: strategy.primaryColor.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReliabilityStatsPage(
                                  score: userProfile.reliabilityScore,
                                  strategy: strategy,
                                  userId: user.uid,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: strategy.primaryColor.withOpacity(0.1)),
                              gradient: LinearGradient(
                                colors: [strategy.backgroundColor.withOpacity(0.6), strategy.backgroundColor.withOpacity(0.2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: Icon(strategy.icon, color: strategy.primaryColor, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Reliability Score", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text("${userProfile.reliabilityScore}", style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                                              const Text("/100", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: userProfile.reliabilityScore / 100,
                                    backgroundColor: Colors.white,
                                    valueColor: AlwaysStoppedAnimation<Color>(strategy.barColor),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionContainer(
                      title: "Contact Information",
                      children: [
                        _buildListTile(Icons.email_outlined, "Email", userProfile.email),
                        const Divider(),
                        _buildListTile(Icons.phone_outlined, "Phone", userProfile.phone),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSectionContainer(
                      title: "My Skills",
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: userProfile.skills.map((s) => _buildSkillChip(s)).toList(),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),

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
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      width: 100, // Reduced width slightly to fit 3 items comfortably
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 24)),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildListTile(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.grey[600], size: 20)),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    ]));
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

// ... (EditProfilePage remains the same)
class EditProfilePage extends StatefulWidget {
  final UserProfile currentProfile;
  final String userId;

  const EditProfilePage({super.key, required this.currentProfile, required this.userId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final TextEditingController _customSkillController = TextEditingController(); // NEW
  Set<String> _selectedSkills = {};

  final List<String> _commonSkills = [
    // Original Skills
    "Farming", "Agriculture", "Driving", "Carpentry",
    "Plumbing", "Electrical", "Cooking", "Sewing",
    "Construction", "Welding", "Painting", "Gardening",
    "Computer Basics", "Accounting", "Teaching",

    // NEW Expanded Skills
    "Digital Literacy", "Event Planning", "Public Speaking", "First Aid",
    "Childcare", "Elderly Care", "Translation", "Graphic Design",
    "Photography", "Video Editing", "Social Media", "Logistics",
    "Data Entry", "Tutoring", "Cleaning", "Food Safety"
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile.name);
    _locationController = TextEditingController(text: widget.currentProfile.location);
    _emailController = TextEditingController(text: widget.currentProfile.email);
    _phoneController = TextEditingController(text: widget.currentProfile.phone);
    _selectedSkills = Set.from(widget.currentProfile.skills);
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  // Method to add custom skill
  void _addCustomSkill() {
    final text = _customSkillController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        // Capitalize first letter for consistency
        String formatted = text[0].toUpperCase() + text.substring(1);
        _selectedSkills.add(formatted);
        _customSkillController.clear();
      });
    }
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
                  'village': _locationController.text,
                  'email': _emailController.text,
                  'phone': _phoneController.text,
                  'skills': _selectedSkills.toList(),
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
              _buildTextField("Location", _locationController, Icons.location_on),

              const SizedBox(height: 24),
              _buildSectionTitle("Contact Info"),
              _buildTextField("Email", _emailController, Icons.email),
              _buildTextField("Phone", _phoneController, Icons.phone),

              const SizedBox(height: 24),
              _buildSectionTitle("Skills"),

              // 1. Custom Skill Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customSkillController,
                      decoration: InputDecoration(
                        hintText: "Add other skill...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.add_task, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _addCustomSkill,
                      icon: const Icon(Icons.add, color: Color(0xFF1565C0)),
                      tooltip: "Add Skill",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text("Select or add your skills:", style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  // 2. Display User-Added Custom Skills (Chips with Delete)
                  ..._selectedSkills.where((s) => !_commonSkills.contains(s)).map((skill) {
                    return InputChip(
                      label: Text(skill),
                      selected: true,
                      onSelected: (bool selected) {},
                      onDeleted: () => _toggleSkill(skill),
                      selectedColor: const Color(0xFFE3F2FD),
                      deleteIconColor: const Color(0xFF1565C0),
                      labelStyle: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFF1565C0), width: 1),
                      ),
                    );
                  }),

                  // 3. Display Common Skills (Filter Chips)
                  ..._commonSkills.map((skill) {
                    final isSelected = _selectedSkills.contains(skill);
                    return FilterChip(
                      label: Text(skill),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        _toggleSkill(skill);
                      },
                      selectedColor: const Color(0xFFE3F2FD),
                      checkmarkColor: const Color(0xFF1565C0),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF1565C0) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
                          width: 1,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
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

// ===========================================================================
// 5. RELIABILITY STATS SCREEN (UPDATED)
// ===========================================================================

class ReliabilityStatsPage extends StatelessWidget {
  final int score;
  final ReliabilityStrategy strategy;
  final String userId;

  const ReliabilityStatsPage({
    super.key,
    required this.score,
    required this.strategy,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Reliability Analytics", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Use StreamBuilder to get real-time history AND calculate breakdown
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('reliability_history')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // --- CALCULATE BREAKDOWN ---
          int successCount = 0;
          int penaltyCount = 0;
          int noShowCount = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final change = data['change'] as int? ?? 0;

            if (change == 10) successCount++;
            else if (change == -5) penaltyCount++;
            else if (change == -20) noShowCount++;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 15,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(strategy.barColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$score",
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: strategy.primaryColor),
                          ),
                          const Text("Total Score", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: strategy.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: strategy.primaryColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(strategy.icon, size: 32, color: strategy.primaryColor),
                      const SizedBox(height: 8),
                      Text(
                        strategy.label,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: strategy.primaryColor),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "This score reflects your reliability based on leader approvals and job attendance.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- NEW: SCORE BREAKDOWN SECTION ---
                const Align(alignment: Alignment.centerLeft, child: Text("Score Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _buildBreakdownRow(Icons.check_circle_outline, "Verified Success", "$successCount times", "+10 points each", const Color(0xFF43A047)),
                      const Divider(),
                      _buildBreakdownRow(Icons.remove_circle_outline, "Rejection Penalty", "$penaltyCount times", "-5 points each", const Color(0xFFFFA000)),
                      const Divider(),
                      _buildBreakdownRow(Icons.cancel_outlined, "No Show", "$noShowCount times", "-20 points each", const Color(0xFFC62828)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- HOW SCORING WORKS ---
                const Align(alignment: Alignment.centerLeft, child: Text("How Scoring Works", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _buildScoringRule(Icons.add_circle, const Color(0xFF43A047), "Verified Success (+10)", "Leader approves your submission."),
                      const Divider(height: 24),
                      _buildScoringRule(Icons.remove_circle, const Color(0xFFFFA000), "Rejection Penalty (-5)", "Leader rejects your submission due to quality issues."),
                      const Divider(height: 24),
                      _buildScoringRule(Icons.cancel, const Color(0xFFC62828), "No Show (-20)", "Failed to submit work or marked as missed."),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- HISTORY LIST ---
                const Align(alignment: Alignment.centerLeft, child: Text("Points History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),

                if (docs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text("No history available yet.", style: TextStyle(color: Colors.grey))),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Column(
                          children: [
                            _buildHistoryItem(
                              data['project_title'] ?? 'Unknown Project',
                              _formatTimestamp(data['timestamp']),
                              data['change'] as int,
                              data['reason'] ?? 'Update',
                            ),
                            if (doc != docs.last) const Divider(),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    if (timestamp is Timestamp) {
      DateTime dt = timestamp.toDate();
      return "${dt.day}/${dt.month}/${dt.year}";
    }
    return "";
  }

  Widget _buildBreakdownRow(IconData icon, String title, String count, String subtext, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtext, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(count, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String project, String date, int change, String reason) {
    Color color = change > 0 ? Colors.green : Colors.red;
    String sign = change > 0 ? "+" : "";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(reason, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          Text("$sign$change pts", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScoringRule(IconData icon, Color color, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}