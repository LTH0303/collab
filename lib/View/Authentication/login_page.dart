import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ViewModel/AuthViewModel/auth_view_model.dart';
import '../LeaderUserInterface/leader_main_layout.dart';
import '../ParticipantViewInterface/participant_main_layout.dart';
// 注意：上面这个 Participant 导入路径是根据你截图推测的，请根据实际情况调整

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 0: 未选择, 1: Village Leader, 2: Youth Participant
  int _selectedRole = 0;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 触发登录
  void _onLoginPressed(AuthViewModel viewModel) async {
    if (_selectedRole == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择一个角色以继续')),
      );
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入邮箱和密码')),
      );
      return;
    }

    // 调用 ViewModel 的登录方法
    bool success = await viewModel.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _selectedRole,
    );

    if (success && mounted) {
      // 根据角色跳转到不同页面
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
      // 如果失败，显示 ViewModel 中的错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? '登录失败')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听 ViewModel 状态
    final authViewModel = Provider.of<AuthViewModel>(context);

    final Color primaryColor = Theme.of(context).primaryColor;
    final Color leaderBorderColor =
    _selectedRole == 1 ? primaryColor : Colors.grey.shade300;
    final Color youthBorderColor =
    _selectedRole == 2 ? primaryColor : Colors.grey.shade300;
    final double leaderBorderWidth = _selectedRole == 1 ? 2.5 : 1.0;
    final double youthBorderWidth = _selectedRole == 2 ? 2.5 : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Logo ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D57),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Smart Village Advisor',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D57),
                  ),
                ),
                const SizedBox(height: 40),

                // --- 角色选择 ---
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Your Role',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Village Leader Card
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 1),
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: leaderBorderColor,
                              width: leaderBorderWidth,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D57),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.roofing,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Village Leader',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Youth Participant Card
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 2),
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: youthBorderColor,
                              width: youthBorderWidth,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E88E5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Youth Participant',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // --- 登录表单 ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: authViewModel.isLoading
                              ? null
                              : () => _onLoginPressed(authViewModel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedRole == 2
                                ? const Color(0xFF1E88E5)
                                : const Color(0xFF2E7D57),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: authViewModel.isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : Text(
                            _selectedRole == 0
                                ? 'Select a Role To Continue'
                                : 'Login as ${_selectedRole == 1 ? "Leader" : "Youth"}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
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
}