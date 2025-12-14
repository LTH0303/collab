import 'package:flutter/material.dart';
// 请确保路径正确引入你的 ViewModel 和 Model
import '../../ViewModel/CommunityViewModel/community_view_model.dart';
import '../../models/Community/post_model.dart';

class CommunityHubPage extends StatefulWidget {
  const CommunityHubPage({super.key});

  @override
  State<CommunityHubPage> createState() => _CommunityHubPageState();
}

class _CommunityHubPageState extends State<CommunityHubPage> {
  final CommunityViewModel _viewModel = CommunityViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadPosts();
  }

  // --- 交互功能弹窗 ---

  // 1. 显示创建贴文面板
  void _showAddPostSheet() {
    final TextEditingController postController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottomPadding + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text("Create Post", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: postController,
                decoration: const InputDecoration(
                  hintText: "Share your story or progress...",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (postController.text.isNotEmpty) {
                    // 调用 ViewModel 发布帖子
                    _viewModel.addPost(postController.text);
                    Navigator.pop(context); // 关闭弹窗
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post published!')));
                  }
                },
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 45), backgroundColor: const Color(0xFF2D6A4F)),
                child: const Text("Post"),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. 显示评论面板
  void _showCommentSheet(PostModel post) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const Padding(padding: EdgeInsets.all(12.0), child: Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              const Divider(height: 1),

              // 评论列表
              Expanded(
                child: post.comments.isEmpty
                    ? const Center(child: Text("No comments yet.", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: post.comments.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: Text(post.comments[index]),
                      ),
                    );
                  },
                ),
              ),

              // 输入框
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF2D6A4F)),
                      onPressed: () {
                        if (commentController.text.isNotEmpty) {
                          // 调用 ViewModel 添加评论
                          _viewModel.addComment(post.id, commentController.text);
                          Navigator.pop(context); // 关闭弹窗 (为了刷新简单，先关闭)
                          // 提示
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment added!')));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. 显示分享选项
  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Share to", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareIcon(Icons.chat, "WhatsApp", Colors.green),
                _buildShareIcon(Icons.facebook, "Facebook", Colors.blue),
                _buildShareIcon(Icons.copy, "Copy Link", Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareIcon(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Shared to $label (Demo)")));
      },
      child: Column(
        children: [
          CircleAvatar(radius: 24, backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // --- 主界面构建 ---

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          body: SafeArea(
            child: _viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfoHeader(),
                  _buildCustomTabBar(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildOrangeBanner(),
                  ),
                  const SizedBox(height: 24),

                  // 标题 + 创建贴文按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Community Showcase", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        // [新增] 这里的 + 号现在可以点击了
                        InkWell(
                          onTap: _showAddPostSheet,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: const Color(0xFF5F9EA0), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 帖子列表
                  if (_viewModel.posts.isEmpty)
                    const Padding(padding: EdgeInsets.all(20.0), child: Text("No posts yet."))
                  else
                    ..._viewModel.posts.map((post) => _buildPostCard(post)),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFF2D6A4F), child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(post.userRole, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text(post.content, style: const TextStyle(fontSize: 14))),
          const SizedBox(height: 8),

          if (post is ImagePostModel)
            Container(margin: const EdgeInsets.only(top: 8), height: 200, width: double.infinity, color: Colors.grey[200], child: const Icon(Icons.image, size: 50, color: Colors.grey)),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("${post.likeCount} likes", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    Text("${post.comments.length} comments", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(width: 16),
                    // [新增] Share 按钮点击事件
                    GestureDetector(
                      onTap: _showShareOptions,
                      child: const Row(children: [Icon(Icons.share, size: 16, color: Colors.blue), SizedBox(width: 4), Text("Share", style: TextStyle(color: Colors.blue))]),
                    ),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _viewModel.toggleLike(post.id),
                  icon: Icon(post.isLiked ? Icons.favorite : Icons.favorite_border, color: post.isLiked ? Colors.red : Colors.grey),
                  label: Text("Like", style: TextStyle(color: post.isLiked ? Colors.red : Colors.grey)),
                ),
                // [新增] Comment 按钮点击事件 -> 打开评论面板
                TextButton.icon(
                  onPressed: () => _showCommentSheet(post),
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                  label: const Text("Comment", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 辅助 UI 组件 (保持不变) ---
  Widget _buildUserInfoHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF2D6A4F), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.sentiment_satisfied_alt, color: Colors.white, size: 30)),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Tester", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text("N/A", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600))]),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(color: Colors.white, padding: const EdgeInsets.only(bottom: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildTabItem(Icons.smart_toy_outlined, "AI Planner", false), _buildTabItem(Icons.assignment_outlined, "Projects", false), _buildTabItem(Icons.bar_chart_outlined, "Impact", false), _buildTabItem(Icons.people_alt_outlined, "Community", true)]));
  }

  Widget _buildTabItem(IconData icon, String label, bool isActive) {
    return Column(children: [Icon(icon, color: isActive ? const Color(0xFF2D6A4F) : Colors.grey, size: 24), const SizedBox(height: 4), Text(label, style: TextStyle(color: isActive ? const Color(0xFF2D6A4F) : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 12))]);
  }

  Widget _buildOrangeBanner() {
    return Container(width: double.infinity, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFA726), Color(0xFFFF7043)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))]), padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.emoji_events, color: Colors.white, size: 24)), const SizedBox(width: 12), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Village Project of the Month", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), Text("Celebrating our community success", style: TextStyle(color: Colors.white70, fontSize: 12))])]), const SizedBox(height: 16), Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Community Hall Renovation", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text("Kampung Baru transformed their 50-year-old hall into a modern community space", style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4)), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildBannerStat(Icons.people, "12 Youth"), _buildBannerStat(Icons.monetization_on, "RM 15,000"), _buildBannerStat(Icons.access_time, "3 Weeks")])]))]));
  }

  Widget _buildBannerStat(IconData icon, String text) {
    return Row(children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 4), Text(text, style: const TextStyle(color: Colors.white, fontSize: 12))]);
  }
}