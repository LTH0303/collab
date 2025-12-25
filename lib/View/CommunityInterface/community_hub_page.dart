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

  // Helper to simulate image picking since we don't have a real device picker here
  Future<String?> _mockPickImage() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Return a random image from picsum
    return "https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/400/300";
  }

  void _showAddPostSheet() {
    final TextEditingController postController = TextEditingController();
    String? selectedImageUrl; // Local state for the modal

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        // Use StatefulBuilder to update the bottom sheet when an image is selected
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomPadding + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),

                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Create Post", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Text Input
                  TextField(
                    controller: postController,
                    decoration: const InputDecoration(
                      hintText: "Share your story, announcement, or progress...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: 4,
                    minLines: 2,
                    style: const TextStyle(fontSize: 16),
                  ),

                  // Image Preview Area
                  if (selectedImageUrl != null) ...[
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            selectedImageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, _, __) => Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedImageUrl = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),

                  // Actions Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Photo Button
                      TextButton.icon(
                        onPressed: () async {
                          final url = await _mockPickImage();
                          setModalState(() {
                            selectedImageUrl = url;
                          });
                        },
                        icon: const Icon(Icons.image, color: Color(0xFF2D6A4F)),
                        label: const Text("Add Photo", style: TextStyle(color: Color(0xFF2D6A4F))),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE8F5E9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),

                      // Post Button
                      FilledButton(
                        onPressed: () async {
                          if (postController.text.isNotEmpty || selectedImageUrl != null) {
                            Navigator.pop(context); // Close first
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publishing...')));

                            await _viewModel.addPost(
                                postController.text,
                                imageUrl: selectedImageUrl
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text("Post"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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