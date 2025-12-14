import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewModel/AuthViewModel/auth_view_model.dart';
import '../LeaderUserInterface/leader_main_layout.dart';
import '../ParticipantViewInterface/participant_main_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 0: Unselected, 1: Leader, 2: Youth
  int _selectedRole = 0;
  bool _isLogin = true; // NEW: Toggle between Login and Register

  final TextEditingController _nameController = TextEditingController(); // NEW
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _onActionPressed(AuthViewModel viewModel) async {
    if (_selectedRole == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role to continue')),
      );
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Validation for Registration
    if (!_isLogin && _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    bool success;
    if (_isLogin) {
      success = await viewModel.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole,
      );
    } else {
      success = await viewModel.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole,
        _nameController.text.trim(),
      );
    }

    if (success && mounted) {
      if (_selectedRole == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LeaderMainLayout()),
        );
      } else if (_selectedRole == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ParticipantMainLayout()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Authentication failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    // Dynamic Colors based on role
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color leaderBorderColor = _selectedRole == 1 ? const Color(0xFF2E7D57) : Colors.grey.shade300;
    final Color youthBorderColor = _selectedRole == 2 ? const Color(0xFF1E88E5) : Colors.grey.shade300;
    final double leaderBorderWidth = _selectedRole == 1 ? 2.5 : 1.0;
    final double youthBorderWidth = _selectedRole == 2 ? 2.5 : 1.0;

    // UI Logic
    String actionButtonText;
    if (_selectedRole == 0) {
      actionButtonText = "Select a Role";
    } else {
      String roleName = _selectedRole == 1 ? "Leader" : "Youth";
      actionButtonText = _isLogin ? "Login as $roleName" : "Register as $roleName";
    }

    Color activeColor = _selectedRole == 2 ? const Color(0xFF1E88E5) : const Color(0xFF2E7D57);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Title
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.location_city, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Smart Village Advisor',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D57)),
                ),
                const SizedBox(height: 40),

                // Role Selection
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isLogin ? 'Login to Dashboard' : 'Create New Account',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 16),

                // Role Cards
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 1),
                        child: _buildRoleCard("Village Leader", Icons.roofing, leaderBorderColor, const Color(0xFF2E7D57), leaderBorderWidth),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 2),
                        child: _buildRoleCard("Youth Participant", Icons.person, youthBorderColor, const Color(0xFF1E88E5), youthBorderWidth),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field (Register Only)
                      if (!_isLogin) ...[
                        const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Ahmad bin Ali',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Email Field
                      const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'your.email@example.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: authViewModel.isLoading ? null : () => _onActionPressed(authViewModel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: authViewModel.isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(actionButtonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Toggle Login/Register
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              // Optional: Clear fields
                              // _emailController.clear();
                              // _passwordController.clear();
                              // _nameController.clear();
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              text: _isLogin ? "Don't have an account? " : "Already have an account? ",
                              style: const TextStyle(color: Colors.grey),
                              children: [
                                TextSpan(
                                  text: _isLogin ? "Sign Up" : "Login",
                                  style: TextStyle(color: activeColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, IconData icon, Color borderColor, Color iconColor, double borderWidth) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}