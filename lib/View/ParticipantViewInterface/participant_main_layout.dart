import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Ensure these paths match your folder structure exactly
import '../Authentication/login_page.dart';
import 'participant_job_list_screen.dart';

// ===========================================================================
// 1. DATA MODELS & STRATEGY (State & Logic)
// ===========================================================================

class UserProfile {
  String name;
  String age;
  String location;
  String email;
  String phone;
  List<String> skills;

  UserProfile({
    required this.name,
    required this.age,
    required this.location,
    required this.email,
    required this.phone,
    required this.skills,
  });
}

// Abstract Strategy Interface for Reliability
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

// ===========================================================================
// 2. MAIN LAYOUT (Manages State)
// ===========================================================================

class ParticipantMainLayout extends StatefulWidget {
  const ParticipantMainLayout({super.key});

  @override
  State<ParticipantMainLayout> createState() => _ParticipantMainLayoutState();
}

class _ParticipantMainLayoutState extends State<ParticipantMainLayout> {
  int _currentIndex = 0;

  // --- STATE: User Profile Data (Lifted State) ---
  UserProfile _userProfile = UserProfile(
    name: "Ahmad bin Ali",
    age: "22",
    location: "Kampung Baru",
    email: "ahmad.youth@kampungbaru.my",
    phone: "+60 19-876 5432",
    skills: ["Agriculture", "Construction"],
  );

  void _updateProfile(UserProfile newProfile) {
    setState(() {
      _userProfile = newProfile;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We construct pages here to pass the state
    final List<Widget> pages = [
      ParticipantJobBoard(), // Tab 0
      const Scaffold(body: Center(child: Text("My Applications (Coming Soon)"))), // Tab 1
      ParticipantProfilePage( // Tab 2
        userProfile: _userProfile,
        onEditProfile: _updateProfile,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onTabTapped,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// ===========================================================================
// 3. PROFILE PAGE (UI)
// ===========================================================================

class ParticipantProfilePage extends StatelessWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onEditProfile;

  const ParticipantProfilePage({
    super.key,
    required this.userProfile,
    required this.onEditProfile,
  });

  ReliabilityStrategy _getReliabilityStrategy(int score) {
    if (score >= 80) return HighReliabilityStrategy();
    if (score >= 50) return MediumReliabilityStrategy();
    return LowReliabilityStrategy();
  }

  @override
  Widget build(BuildContext context) {
    const int currentScore = 85;
    final ReliabilityStrategy strategy = _getReliabilityStrategy(currentScore);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // --- EDIT PROFILE BUTTON ---
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(currentProfile: userProfile),
                ),
              );
              if (result != null && result is UserProfile) {
                onEditProfile(result);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
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
            // --- PROFILE HEADER ---
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
                    backgroundColor: Color(0xFF1E88E5),
                    child: Icon(Icons.face, size: 45, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userProfile.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${userProfile.age} years old • ${userProfile.location}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- STATS ROW ---
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

            // --- RELIABILITY SCORE BUTTON ---
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: strategy.primaryColor.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReliabilityStatsPage(score: currentScore, strategy: strategy),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: strategy.primaryColor.withOpacity(0.1)),
                      gradient: LinearGradient(
                        colors: [strategy.backgroundColor.withOpacity(0.5), strategy.backgroundColor.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Icon(strategy.icon, color: strategy.primaryColor, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Reliability Score", style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text("$currentScore", style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)),
                                      const Text("/100", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: strategy.primaryColor, borderRadius: BorderRadius.circular(12)),
                                        child: Text(strategy.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: currentScore / 100,
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

            // --- CONTACT INFO ---
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
                  _buildInfoTile(Icons.email_outlined, "Email", userProfile.email),
                  const Divider(height: 1, indent: 60),
                  _buildInfoTile(Icons.phone_outlined, "Phone", userProfile.phone),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- SKILLS ---
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
                children: userProfile.skills.map((s) => _buildSkillChip(s)).toList(),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String count, String label, IconData icon, Color bg, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 22)),
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
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.grey[600], size: 20)),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

// ===========================================================================
// 4. EDIT PROFILE PAGE (New Feature)
// ===========================================================================

class EditProfilePage extends StatefulWidget {
  final UserProfile currentProfile;

  const EditProfilePage({super.key, required this.currentProfile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _skillsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile.name);
    _ageController = TextEditingController(text: widget.currentProfile.age);
    _locationController = TextEditingController(text: widget.currentProfile.location);
    _emailController = TextEditingController(text: widget.currentProfile.email);
    _phoneController = TextEditingController(text: widget.currentProfile.phone);
    _skillsController = TextEditingController(text: widget.currentProfile.skills.join(", "));
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Create Updated Profile
                final updatedProfile = UserProfile(
                  name: _nameController.text,
                  age: _ageController.text,
                  location: _locationController.text,
                  email: _emailController.text,
                  phone: _phoneController.text,
                  skills: _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                );
                // Return Data
                Navigator.pop(context, updatedProfile);
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
              _buildTextField("Age", _ageController, Icons.calendar_today),
              _buildTextField("Location", _locationController, Icons.location_on),

              const SizedBox(height: 24),
              _buildSectionTitle("Contact Info"),
              _buildTextField("Email", _emailController, Icons.email),
              _buildTextField("Phone", _phoneController, Icons.phone),

              const SizedBox(height: 24),
              _buildSectionTitle("Skills"),
              const Text("Separate skills with commas (e.g. Farming, Driving)", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildTextField("Skills", _skillsController, Icons.school, maxLines: 2),
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

// ===========================================================================
// 5. RELIABILITY STATS SCREEN
// ===========================================================================

class ReliabilityStatsPage extends StatelessWidget {
  final int score;
  final ReliabilityStrategy strategy;

  const ReliabilityStatsPage({
    super.key,
    required this.score,
    required this.strategy,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- 1. BIG SCORE INDICATOR ---
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

            // --- 2. STATUS CARD ---
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
                    "You are consistently meeting project expectations. Keep up the great work!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 3. ACTIVITY SUMMARY ---
            const Align(alignment: Alignment.centerLeft, child: Text("Activity Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                children: [
                  _buildPointSummaryRow(Icons.check_circle_outline, "Verified Success", "12 times", "+60 pts", const Color(0xFF43A047)),
                  const Divider(),
                  _buildPointSummaryRow(Icons.remove_circle_outline, "Rejection Penalty", "1 time", "-5 pts", const Color(0xFFE57373)),
                  const Divider(),
                  _buildPointSummaryRow(Icons.event_busy, "No Show", "0 times", "-0 pts", Colors.grey),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 4. HOW SCORING WORKS ---
            const Align(alignment: Alignment.centerLeft, child: Text("How Scoring Works", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildScoringRule(Icons.add_circle, const Color(0xFF43A047), "Verified Success (+10)", "Leader approves your uploaded proof and clicks \"Approve & Next\". Work meets quality standards."),
                  const Divider(height: 24),
                  _buildScoringRule(Icons.remove_circle, const Color(0xFFFFA000), "Rejection Penalty (-5)", "You uploaded proof but leader clicked \"Reject\" or \"Request Redo\". Work didn't meet standards initially."),
                  const Divider(height: 24),
                  _buildScoringRule(Icons.cancel, const Color(0xFFC62828), "No Show (-20)", "Leader clicks \"Next Phase\" but you have 0 uploaded proofs. This counts as abandoning the job."),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 5. HISTORY ---
            const Align(alignment: Alignment.centerLeft, child: Text("History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildHistoryItem("Community Hall Cleanup", "12 Oct 2025", "+5 pts"),
                  const Divider(),
                  _buildHistoryItem("River Bank Planting", "05 Oct 2025", "+8 pts"),
                  const Divider(),
                  _buildHistoryItem("School Fence Repair", "28 Sep 2025", "+4 pts"),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPointSummaryRow(IconData icon, String title, String count, String points, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(count, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
          Text(points, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildScoringRule(IconData icon, Color color, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(margin: const EdgeInsets.only(top: 2), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)), const SizedBox(height: 4), Text(description, style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4))])),
      ],
    );
  }

  Widget _buildHistoryItem(String project, String date, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(project, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
          Text(points, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}