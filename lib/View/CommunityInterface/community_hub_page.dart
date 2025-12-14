import 'package:flutter/material.dart';
import '../../ViewModel/CommunityViewModel/community_view_model.dart';
import 'post_card_factory.dart'; // Import the UI Factory

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
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),),
              const SizedBox(height: 16),
              const Text("Create Post", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: postController,
                decoration: const InputDecoration(
                  hintText: "Share your story, announcement, or progress...",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (postController.text.isNotEmpty) {
                    Navigator.pop(context); // Close first
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publishing...')));
                    await _viewModel.addPost(postController.text);
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

  // --- INTERACTION HANDLERS ---

  void _onLikePressed(String postId) {
    _viewModel.toggleLike(postId);
  }

  void _onCommentPressed(String postId, List<String> currentComments) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Expanded(
                child: currentComments.isEmpty
                    ? const Center(child: Text("No comments yet", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  itemCount: currentComments.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(Icons.comment, size: 16, color: Colors.grey),
                    title: Text(currentComments[index], style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: commentController, decoration: const InputDecoration(hintText: "Add comment..."))),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF2D6A4F)),
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        _viewModel.addComment(postId, commentController.text);
                        Navigator.pop(ctx);
                      }
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F9FC),
          body: _viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: () async => _viewModel.loadPosts(),
            child: CustomScrollView(
              slivers: [
                // 1. App Bar
                const SliverAppBar(
                  title: Text("Community Hub", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  floating: true,
                  automaticallyImplyLeading: false,
                ),

                // 2. Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildProjectOfTheMonthBanner(),
                  ),
                ),

                // 3. Title & Add Button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Community Showcase", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // 4. Post List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final post = _viewModel.posts[index];

                      // Use Factory to create the card AND pass the interaction handlers
                      return PostCardFactory.createPostCard(
                        post: post,
                        onLike: _onLikePressed,
                        onComment: _onCommentPressed,
                      );
                    },
                    childCount: _viewModel.posts.length,
                  ),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectOfTheMonthBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFA726), Color(0xFFFF7043)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.emoji_events, color: Colors.white, size: 24)),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Village Project of the Month", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), Text("Celebrating our community success", style: TextStyle(color: Colors.white70, fontSize: 12))])
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Community Hall Renovation", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Kampung Baru transformed their 50-year-old hall into a modern community space", style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                _BannerStat(icon: Icons.people, text: "12 Youth"),
                _BannerStat(icon: Icons.monetization_on, text: "RM 15,000"),
                _BannerStat(icon: Icons.access_time, text: "3 Weeks"),
              ])
            ]),
          )
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BannerStat({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 4), Text(text, style: const TextStyle(color: Colors.white, fontSize: 12))]);
  }
}