import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Authentication/login_page.dart';

// ===========================================================================
// 1. STRATEGY PATTERN CLASSES (Logic for Colors & Icons)
// ===========================================================================

abstract class ReliabilityStrategy {
  String get label;
  Color get primaryColor;      // Text & Icon color
  Color get backgroundColor;   // Button/Card background color
  Color get barColor;          // Progress bar color
  IconData get icon;
}

// Green Strategy (Score >= 80)
class HighReliabilityStrategy implements ReliabilityStrategy {
  @override
  String get label => "High Reliability";
  @override
  Color get primaryColor => const Color(0xFF2E7D32); // Dark Green
  @override
  Color get backgroundColor => const Color(0xFFE8F5E9); // Light Green
  @override
  Color get barColor => const Color(0xFF43A047);
  @override
  IconData get icon => Icons.verified_user;
}

// Amber Strategy (Score 50-79)
class MediumReliabilityStrategy implements ReliabilityStrategy {
  @override
  String get label => "Medium Reliability";
  @override
  Color get primaryColor => const Color(0xFFFFA000); // Dark Amber
  @override
  Color get backgroundColor => const Color(0xFFFFF8E1); // Light Amber
  @override
  Color get barColor => const Color(0xFFFFC107);
  @override
  IconData get icon => Icons.star_half;
}

// Red Strategy (Score < 50)
class LowReliabilityStrategy implements ReliabilityStrategy {
  @override
  String get label => "Needs Improvement";
  @override
  Color get primaryColor => const Color(0xFFC62828); // Dark Red
  @override
  Color get backgroundColor => const Color(0xFFFFEBEE); // Light Red
  @override
  Color get barColor => const Color(0xFFE57373);
  @override
  IconData get icon => Icons.warning_amber_rounded;
}

// ===========================================================================
// 2. PARTICIPANT PROFILE PAGE (Your Layout + Reliability Button)
// ===========================================================================

class ParticipantProfilePage extends StatelessWidget {
  const ParticipantProfilePage({super.key});

  // Helper to determine strategy based on score
  ReliabilityStrategy _getReliabilityStrategy(int score) {
    if (score >= 80) return HighReliabilityStrategy();
    if (score >= 50) return MediumReliabilityStrategy();
    return LowReliabilityStrategy();
  }

  @override
  Widget build(BuildContext context) {
    // --- MOCK DATA: Change this to test colors (e.g., 85, 60, 40) ---
    const int currentScore = 85;
    final ReliabilityStrategy strategy = _getReliabilityStrategy(currentScore);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
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
              backgroundColor: Color(0xFF1E88E5), // Blue for Youth
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              "Ahmad bin Ali",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),

            // Dynamic Label based on Strategy
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(strategy.icon, color: strategy.primaryColor, size: 16),
                const SizedBox(width: 4),
                Text(strategy.label, style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD), // Light Blue pill
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Kampung Baru",
                style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. Stats Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("1", "Active\nJob", Icons.work_outline, Colors.blue),
                _buildStatCard("RM 850", "Earnings", Icons.account_balance_wallet_outlined, Colors.green),
                _buildStatCard("5", "Skills", Icons.school_outlined, Colors.orange),
              ],
            ),

            const SizedBox(height: 24),

            // =================================================================
            // NEW: CLICKABLE RELIABILITY SCORE BUTTON (Navigates to Stats Page)
            // =================================================================
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
                    // Navigate to the detailed Stats Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReliabilityStatsPage(score: currentScore, strategy: strategy),
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
                                      Text("$currentScore", style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
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
            // =================================================================

            const SizedBox(height: 24),

            // --- 3. Contact Info ---
            _buildSectionContainer(
              title: "Contact Information",
              children: [
                _buildListTile(Icons.email_outlined, "Email", "ali.youth@gmail.com"),
                const Divider(),
                _buildListTile(Icons.phone_outlined, "Phone", "+60 19-876 5432"),
              ],
            ),
            const SizedBox(height: 16),

            // --- 4. Skills ---
            _buildSectionContainer(
              title: "My Skills",
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSkillChip("Agriculture"),
                    _buildSkillChip("Construction"),
                    _buildSkillChip("Manual Labor"),
                  ],
                )
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
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

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

// ===========================================================================
// 3. NEW PAGE: RELIABILITY STATS SCREEN (Details Page)
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

            // --- 3. ACTIVITY SUMMARY (Requested) ---
            const Align(alignment: Alignment.centerLeft, child: Text("Activity Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
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

            // --- 4. HOW SCORING WORKS (Requested) ---
            const Align(alignment: Alignment.centerLeft, child: Text("How Scoring Works", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildScoringRule(
                      Icons.add_circle,
                      const Color(0xFF43A047), // Green
                      "Verified Success (+10)",
                      "Leader approves your uploaded proof and clicks \"Approve & Next\". Work meets quality standards."
                  ),
                  const Divider(height: 24),
                  _buildScoringRule(
                      Icons.remove_circle,
                      const Color(0xFFFFA000), // Amber
                      "Rejection Penalty (-5)",
                      "You uploaded proof but leader clicked \"Reject\" or \"Request Redo\". Work didn't meet standards initially."
                  ),
                  const Divider(height: 24),
                  _buildScoringRule(
                      Icons.cancel,
                      const Color(0xFFC62828), // Red
                      "No Show (-20)",
                      "Leader clicks \"Next Phase\" but you have 0 uploaded proofs. This counts as abandoning the job."
                  ),
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

  // --- HELPERS ---

  Widget _buildPointSummaryRow(IconData icon, String title, String count, String points, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(count, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(points, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _buildHistoryItem(String project, String date, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Text(points, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}