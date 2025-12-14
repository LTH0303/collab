import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign In
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Up (New Method)
  Future<User?> signUp(String email, String password, String role, String name) async {
    try {
      // 1. Create User in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // 2. Update Display Name in Auth Profile
        await user.updateDisplayName(name);

        // 3. Create User Document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'role': role, // 'leader' or 'participant'
          'name': name,
          'created_at': FieldValue.serverTimestamp(),
          'skills': role == 'participant' ? [] : null, // Initialize empty skills for youth
          'village': 'Kampung Baru', // Default for demo
        });
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Get User Role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['role'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception("Error fetching user role: $e");
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}