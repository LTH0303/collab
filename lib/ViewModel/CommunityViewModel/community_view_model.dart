import 'package:flutter/material.dart';
import '../../models/Community/post_model.dart';

class CommunityViewModel extends ChangeNotifier {
  // 状态：帖子列表
  List<PostModel> _posts = [];
  bool _isLoading = false;

  // Getter
  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;

  // 初始化数据
  void loadPosts() {
    _isLoading = true;
    notifyListeners();

    // 模拟延迟加载
    Future.delayed(const Duration(seconds: 1), () {
      _posts = [
        PostFactory.createPost({
          'id': '1',
          'userName': 'Village Leader',
          'userRole': 'Kampung Baru',
          'content': 'Our community hall is now complete!',
          'imageUrl': 'https://example.com/hall.jpg', // 模拟图片
          'likeCount': 24,
          'isLiked': false,
          'comments': ['Great job!', 'Amazing work team!']
        }),
        PostFactory.createPost({
          'id': '2',
          'userName': 'Ahmad',
          'userRole': 'Youth',
          'content': 'Looking for volunteers for the cleanup drive next Sunday.',
          'likeCount': 5,
          'isLiked': false,
          'comments': []
        }),
      ];
      _isLoading = false;
      notifyListeners();
    });
  }

  // --- 交互逻辑 ---

  // 1. 点赞
  void toggleLike(String postId) {
    final post = _posts.firstWhere((p) => p.id == postId);
    if (post.isLiked) {
      post.likeCount--;
      post.isLiked = false;
    } else {
      post.likeCount++;
      post.isLiked = true;
    }
    notifyListeners();
  }

  // 2. [新增] 添加评论
  void addComment(String postId, String commentContent) {
    final post = _posts.firstWhere((p) => p.id == postId);
    // 这里为了演示简单，直接存字符串。
    // 在真实App中，你可能需要存一个 Map 包含 {userName: "Tester", content: ...}
    post.comments.add(commentContent);
    notifyListeners();
  }

  // 3. [新增] 发布新贴文
  void addPost(String content) {
    // 使用工厂创建新帖子
    final newPost = PostFactory.createPost({
      'id': DateTime.now().toString(), // 生成临时ID
      'userName': 'Tester',            // 暂时写死当前用户
      'userRole': 'N/A',
      'content': content,
      'likeCount': 0,
      'isLiked': false,
      'comments': <String>[],
    });

    _posts.insert(0, newPost); // 插到列表最前面
    notifyListeners(); // 通知 UI 刷新
  }
}