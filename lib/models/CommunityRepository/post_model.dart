// 1. 抽象产品 (Abstract Product)
abstract class PostModel {
  final String id;
  final String userName;
  final String userRole;
  final String content;
  int likeCount;
  bool isLiked;
  final List<String> comments;

  PostModel({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.content,
    this.likeCount = 0,
    this.isLiked = false,
    this.comments = const [],
  });
}

// 2. 具体产品 A (Concrete Product A): 带图片的帖子
class ImagePostModel extends PostModel {
  final String imageUrl;

  ImagePostModel({
    required super.id,
    required super.userName,
    required super.userRole,
    required super.content,
    required this.imageUrl,
    super.likeCount,
    super.isLiked,
    super.comments,
  });
}

// 3. 具体产品 B (Concrete Product B): 纯文字帖子 (或者视频帖子等)
class TextPostModel extends PostModel {
  TextPostModel({
    required super.id,
    required super.userName,
    required super.userRole,
    required super.content,
    super.likeCount,
    super.isLiked,
    super.comments,
  });
}

// 4. 工厂类 (The Factory) - 这就是你要的 Design Pattern!
class PostFactory {
  /// 工厂方法：根据传入数据的特征，决定生产哪种 Post 对象
  static PostModel createPost(Map<String, dynamic> json) {
    if (json.containsKey('imageUrl') && json['imageUrl'] != null) {
      return ImagePostModel(
        id: json['id'],
        userName: json['userName'],
        userRole: json['userRole'],
        content: json['content'],
        imageUrl: json['imageUrl'],
        likeCount: json['likeCount'] ?? 0,
        isLiked: json['isLiked'] ?? false,
        comments: List<String>.from(json['comments'] ?? []),
      );
    } else {
      return TextPostModel(
        id: json['id'],
        userName: json['userName'],
        userRole: json['userRole'],
        content: json['content'],
        likeCount: json['likeCount'] ?? 0,
        isLiked: json['isLiked'] ?? false,
        comments: List<String>.from(json['comments'] ?? []),
      );
    }
  }
}