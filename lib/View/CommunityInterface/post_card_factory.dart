// lib/View/CommunityInterface/post_card_factory.dart

import 'package:flutter/material.dart';
import '../../models/CommunityRepository/post_model.dart';

/// --- FACTORY METHOD PATTERN IMPLEMENTATION ---
class PostCardFactory {
  static Widget createPostCard({
    required PostModel post,
    required Function(String postId) onLike,
    required Function(String postId, List<String> comments) onComment,
  }) {
    if (post is ImagePostModel) {
      return ShowcasePostCard(post: post, onLike: onLike, onComment: onComment);
    } else if (post is TextPostModel) {
      return StandardPostCard(post: post, onLike: onLike, onComment: onComment);
    } else {
      return const SizedBox.shrink();
    }
  }
}

/// --- CONCRETE PRODUCT A: Showcase Post (For Projects/Images) ---
class ShowcasePostCard extends StatelessWidget {
  final ImagePostModel post;
  final Function(String postId) onLike;
  final Function(String postId, List<String> comments) onComment;

  const ShowcasePostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF2E7D32),
                      child: Text(
                        post.userName.isNotEmpty ? post.userName[0].toUpperCase() : "U",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("${post.userRole} • Just now", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                // "Showcase" Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyan[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan),
                  ),
                  child: const Text("Project Showcase", style: TextStyle(color: Colors.cyan, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),

          // Image Content
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    Text("Image unavailable", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(post.content, style: const TextStyle(fontSize: 14)),
          ),

          // Footer (Likes/Comments)
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                // [UPDATED] LIKE BUTTON -> Now uses Thumbs Up style
                InkWell(
                  onTap: () => onLike(post.id),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        size: 20,
                        // Update color: Blue for liked (matches StandardPost), Grey for unliked
                        color: post.isLiked ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text("${post.likeCount} Likes", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // COMMENT BUTTON
                InkWell(
                  onTap: () => onComment(post.id, post.comments),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text("${post.comments.length} Comments", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// --- CONCRETE PRODUCT B: Standard Post (Text Only) ---
class StandardPostCard extends StatelessWidget {
  final TextPostModel post;
  final Function(String postId) onLike;
  final Function(String postId, List<String> comments) onComment;

  const StandardPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blueGrey[100],
                child: Text(
                  post.userName.isNotEmpty ? post.userName[0].toUpperCase() : "U",
                  style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(post.userRole, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.content, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              // LIKE BUTTON (Kept consistent)
              InkWell(
                onTap: () => onLike(post.id),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        size: 16,
                        color: post.isLiked ? Colors.blue : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text("${post.likeCount}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // COMMENT BUTTON
              InkWell(
                onTap: () => onComment(post.id, post.comments),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.comment_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text("${post.comments.length}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}