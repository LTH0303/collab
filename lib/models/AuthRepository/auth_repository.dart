import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 登录方法
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow; // 将错误抛给 ViewModel 处理
    }
  }

  // 获取用户角色 (从 Firestore 读取)
  // 假设你在 Firestore 有一个 'users' 集合，文档 ID 是用户的 UID
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        // 获取 'role' 字段，例如 "leader" 或 "participant"
        return (doc.data() as Map<String, dynamic>)['role'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception("无法获取用户角色: $e");
    }
  }

  // 登出
  Future<void> signOut() async {
    await _auth.signOut();
  }
}