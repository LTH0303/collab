import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/AuthRepository/auth_repository.dart';

enum AuthStatus { initial, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _userRole;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get userRole => _userRole;

  bool get isLoading => _status == AuthStatus.loading;

  // Login Logic
  Future<bool> login(String email, String password, int selectedRoleIndex) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      User? user = await _authRepository.signIn(email, password);

      if (user != null) {
        String? role = await _authRepository.getUserRole(user.uid);
        String expectedRole = selectedRoleIndex == 1 ? 'leader' : 'participant';

        if (role == expectedRole) {
          _userRole = role;
          _status = AuthStatus.success;
          notifyListeners();
          return true;
        } else {
          await _authRepository.signOut();
          _status = AuthStatus.error;
          _errorMessage = "Role mismatch. Please login with the correct role.";
          notifyListeners();
          return false;
        }
      } else {
        _status = AuthStatus.error;
        _errorMessage = "Login failed.";
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message ?? "Authentication Error";
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Register Logic (New)
  Future<bool> register(String email, String password, int selectedRoleIndex, String name) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Map index to role string
      String role = selectedRoleIndex == 1 ? 'leader' : 'participant';

      User? user = await _authRepository.signUp(email, password, role, name);

      if (user != null) {
        _userRole = role;
        _status = AuthStatus.success;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = "Registration failed.";
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message ?? "Registration Error";
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