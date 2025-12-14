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

  // --- HELPER: Enforce Persona Names ---
  Future<String> _resolveUserName(User user, String role) async {
    String userName = user.displayName ?? "";

    // 1. Try fetching from DB if local display name is empty
    if (userName.isEmpty) {
      try {
        final userProfile = await _dbService.getUserProfile(user.uid);
        if (userProfile != null && userProfile.containsKey('name')) {
          userName = userProfile['name'];
        }
      } catch (e) {
        print("Error resolving name: $e");
      }
    }

    // 2. If still empty, "User", "Unknown" or "Community Member", enforce the Persona Name
    // This matches the hardcoded names in LeaderProfilePage and ParticipantProfilePage
    if (userName.isEmpty || userName == "User" || userName == "Unknown" || userName == "Community Member") {
      if (role == 'leader') {
        return "Dato' Seri Ahmad";
      } else {
        return "Ahmad bin Ali";
      }
    }

    return userName;
  }

  // --- ACTIONS ---

  Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
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

      try {
        await _dbService.togglePostLike(postId, user.uid, isNowLiked);
      } catch (e) {
        print("Error liking post: $e");
      }
    }
  }

  Future<void> addComment(String postId, String commentContent) async {
    final user = _auth.currentUser;
    String finalComment = commentContent;

    if (user != null) {
      String userRole = _currentUserRole ?? 'participant';
      String name = await _resolveUserName(user, userRole);
      finalComment = "$name: $commentContent";
    }

    await _dbService.addPostComment(postId, finalComment);
  }

  Future<void> addPost(String content, {String? imageUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      String userRole = _currentUserRole ?? 'participant';

      // Use the helper to get the correct name ("Dato'..." or "Ahmad...")
      String userName = await _resolveUserName(user, userRole);

      PostModel newPost;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        newPost = ImagePostModel(
          id: '',
          userId: user.uid,
          userName: userName,
          userRole: userRole,
          content: content,
          imageUrl: imageUrl,
          timestamp: DateTime.now(),
          likeCount: 0,
          isLiked: false,
          comments: [],
        );
      } else {
        newPost = TextPostModel(
          id: '',
          userId: user.uid,
          userName: userName,
          userRole: userRole,
          content: content,
          timestamp: DateTime.now(),
          likeCount: 0,
          isLiked: false,
          comments: [],
        );
      }

      await _dbService.createPost(newPost);

    } catch (e) {
      print("Error adding post: $e");
    }
  }
}