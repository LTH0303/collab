// lib/ViewModel/CommunityViewModel/community_view_model.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/CommunityRepository/post_model.dart';
import '../../models/DatabaseService/database_service.dart';

class CommunityViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _currentUserRole;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;

  // Initialize and Listen
  void loadPosts() {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    // 1. Fetch User Role First to apply visibility rules
    _fetchUserRole(user.uid).then((_) {
      // 2. Listen to posts stream
      _dbService.getPostsStream(user.uid).listen((allPosts) {

        _posts = allPosts;
        _isLoading = false;
        notifyListeners();
      });
    });
  }

  Future<void> _fetchUserRole(String uid) async {
    // We try to get the role from the 'users' collection
    // If not found, we assume 'participant' for safety
    try {
      final userProfile = await _dbService.getUserProfile(uid);
      if (userProfile != null && userProfile.containsKey('role')) {
        _currentUserRole = userProfile['role'];
      } else {
        _currentUserRole = 'participant';
      }
    } catch (e) {
      _currentUserRole = 'participant';
    }
  }

  // --- ACTIONS ---

  Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Optimistic Update (UI updates immediately)
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];

      // Calculate new state logic
      bool isNowLiked;

      if (post.isLiked) {
        post.likeCount--;
        post.isLiked = false;
        isNowLiked = false;
      } else {
        post.likeCount++;
        post.isLiked = true;
        isNowLiked = true;
      }
      notifyListeners();

      // Actual DB Update
      // PASS the new state (isNowLiked) to the service
      try {
        await _dbService.togglePostLike(postId, user.uid, isNowLiked);
      } catch (e) {
        print("Error liking post: $e");
        // Optional: Revert optimistic update here
      }
    }
  }

  Future<void> addComment(String postId, String commentContent) async {
    // Add current user name to comment
    final user = _auth.currentUser;
    String finalComment = commentContent;

    if (user != null) {
      String name = user.displayName ?? "User";
      finalComment = "$name: $commentContent";
    }

    await _dbService.addPostComment(postId, finalComment);
  }

  Future<void> addPost(String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Get Real User Data
      String userName = user.displayName ?? "Unknown";
      String userRole = _currentUserRole ?? 'participant';

      // 2. Create Model
      final newPost = TextPostModel(
        id: '', // DB will assign ID
        userId: user.uid,
        userName: userName,
        userRole: userRole,
        content: content,
        timestamp: DateTime.now(),
        likeCount: 0,
        isLiked: false,
        comments: [],
      );

      // 3. Send to DB
      await _dbService.createPost(newPost);

    } catch (e) {
      print("Error adding post: $e");
    }
  }
}