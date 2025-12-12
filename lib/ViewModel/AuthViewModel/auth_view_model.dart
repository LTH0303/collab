import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/AuthRepository/auth_repository.dart';

enum AuthStatus { initial, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _userRole; // 存储获取到的用户角色

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get userRole => _userRole;

  bool get isLoading => _status == AuthStatus.loading;

  // 登录逻辑
  Future<bool> login(String email, String password, int selectedRoleIndex) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. 进行 Firebase 认证
      User? user = await _authRepository.signIn(email, password);

      if (user != null) {
        // 2. 认证成功后，去 Firestore 获取该用户的角色
        String? role = await _authRepository.getUserRole(user.uid);

        // 3. 验证角色是否匹配
        // 假设 Firestore 里存的是 'leader' 和 'participant'
        String expectedRole = selectedRoleIndex == 1 ? 'leader' : 'participant';

        if (role == expectedRole) {
          _userRole = role;
          _status = AuthStatus.success;
          notifyListeners();
          return true; // 登录成功且角色匹配
        } else {
          // 角色不匹配 (例如用 Leader 账号尝试登录 Youth 入口)
          await _authRepository.signOut();
          _status = AuthStatus.error;
          _errorMessage = "账号角色不匹配。请确认您的身份。";
          notifyListeners();
          return false;
        }
      } else {
        _status = AuthStatus.error;
        _errorMessage = "登录失败，无法获取用户信息。";
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      if (e.code == 'user-not-found') {
        _errorMessage = '该邮箱未注册。';
      } else if (e.code == 'wrong-password') {
        _errorMessage = '密码错误。';
      } else {
        _errorMessage = e.message;
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}