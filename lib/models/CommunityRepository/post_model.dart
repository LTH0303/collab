// lib/models/CommunityRepository/post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Abstract Product
abstract class PostModel {
  final String id;
  final String userId; // New: Bind to specific user
  final String userName;
  final String userRole;
  final String content;
  int likeCount;
  bool isLiked; // Note: In a real app, this depends on the current user. For simple sync, we might load a subcollection or array.
  final List<String> comments;
  final DateTime timestamp; // New: For sorting

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.content,
    this.likeCount = 0,
    this.isLiked = false,
    this.comments = const [],
    required this.timestamp,
  });

  Map<String, dynamic> toJson();
}

// 2. Concrete Product A: Image Post
class ImagePostModel extends PostModel {
  final String imageUrl;

  ImagePostModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userRole,
    required super.content,
    required this.imageUrl,
    super.likeCount,
    super.isLiked,
    super.comments,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'image',
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'content': content,
      'imageUrl': imageUrl,
      'likeCount': likeCount,
      'comments': comments,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

// 3. Concrete Product B: Text Post
class TextPostModel extends PostModel {
  TextPostModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userRole,
    required super.content,
    super.likeCount,
    super.isLiked,
    super.comments,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'text',
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'content': content,
      'likeCount': likeCount,
      'comments': comments,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

// 4. Factory
class PostFactory {
  static PostModel createPost(String docId, Map<String, dynamic> data, String currentUserId) {
    DateTime time = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    // Check if current user liked this post (requires an array of 'likedBy' in DB for robustness,
    // but for now we'll default false or rely on local state if not persistent)
    List<dynamic> likedBy = data['likedBy'] ?? [];
    bool isLikedByMe = likedBy.contains(currentUserId);

    if (data['type'] == 'image' || (data.containsKey('imageUrl') && data['imageUrl'] != null && data['imageUrl'] != '')) {
      return ImagePostModel(
        id: docId,
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? 'Unknown',
        userRole: data['userRole'] ?? 'Participant',
        content: data['content'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        likeCount: (data['likedBy'] as List?)?.length ?? data['likeCount'] ?? 0,
        isLiked: isLikedByMe,
        comments: List<String>.from(data['comments'] ?? []),
        timestamp: time,
      );
    } else {
      return TextPostModel(
        id: docId,
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? 'Unknown',
        userRole: data['userRole'] ?? 'Participant',
        content: data['content'] ?? '',
        likeCount: (data['likedBy'] as List?)?.length ?? data['likeCount'] ?? 0,
        isLiked: isLikedByMe,
        comments: List<String>.from(data['comments'] ?? []),
        timestamp: time,
      );
    }
  }
}