import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/forum_controller.dart';
import '../../../core/theme/flock_theme.dart';
import '../../../models/forum_post.dart';
import '../widgets/post_card.dart';
import '../widgets/category_chip.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class ForumFeedScreen extends StatelessWidget {
  final String buildingId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatarUrl;
  final bool isManagement;

  const ForumFeedScreen({
    super.key,
    required this.buildingId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatarUrl = '',
    this.isManagement = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForumController(),
      child: _ForumFeedView(
        buildingId: buildingId,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserAvatarUrl: currentUserAvatarUrl,
        isManagement: isManagement,
      ),
    );
  }
}

class _ForumFeedView extends StatelessWidget {
  final String buildingId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatarUrl;
  final bool isManagement;

  const _ForumFeedView({
    required this.buildingId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatarUrl,
    required this.isManagement,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ForumController>();
    final hasBuildingContext = buildingId.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: FlockColors.cream,
      appBar: AppBar(
        backgroundColor: FlockColors.cream,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Building Forum',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: FlockColors.darkGreen,
                    letterSpacing: -0.3)),
            const Text('Share with your neighbors',
                style: TextStyle(
                    fontSize: 12,
                    color: FlockColors.textSecondary,
                    fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: hasBuildingContext
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: controller,
                      child: CreatePostScreen(
                        buildingId: buildingId,
                        currentUserId: currentUserId,
                        currentUserName: currentUserName,
                        currentUserAvatarUrl: currentUserAvatarUrl,
                      ),
                    ),
                  ),
                )
            : null,
        backgroundColor: FlockColors.darkGreen,
        foregroundColor: FlockColors.cream,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('New Post',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          if (controller.errorMessage != null)
            _ErrorBanner(
                message: controller.errorMessage!,
                onDismiss: controller.clearError),

          CategoryFilterBar(
              selected: controller.selectedCategory,
              onSelected: controller.setCategory),

          Expanded(
            child: !hasBuildingContext
                ? const _EmptyState(
                    icon: Icons.location_city_outlined,
                    message:
                        'We are still loading your building.\nPlease wait a moment and try again.',
                  )
                : StreamBuilder<List<ForumPost>>(
              stream: controller.postsStream(buildingId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: FlockColors.midGreen));
                }
                if (snapshot.hasError) {
                  final message = _friendlyErrorMessage(snapshot.error);
                  return _EmptyState(
                      icon: Icons.error_outline,
                      message: message);
                }

                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return _EmptyState(
                    icon: Icons.forum_outlined,
                    message: controller.selectedCategory != null
                        ? 'No posts in this category yet.\nBe the first!'
                        : 'No posts yet.\nStart the conversation!',
                  );
                }

                return RefreshIndicator(
                  color: FlockColors.darkGreen,
                  backgroundColor: FlockColors.cream,
                  onRefresh: () async {},
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return PostCard(
                        post: post,
                        currentUserId: currentUserId,
                        isManagement: isManagement,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: controller,
                              child: PostDetailScreen(
                                postId: post.id,
                                currentUserId: currentUserId,
                                currentUserName: currentUserName,
                                currentUserAvatarUrl: currentUserAvatarUrl,
                                isManagement: isManagement,
                              ),
                            ),
                          ),
                        ),
                        onUpvote: () => controller.togglePostUpvote(
                            post.id, currentUserId),
                        onDelete:
                            isManagement || post.authorId == currentUserId
                                ? () => _confirmDelete(
                                    context, controller, post.id)
                                : null,
                        onPin: isManagement
                            ? () => controller.togglePin(
                                post.id, !post.isPinned)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, ForumController controller, String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FlockColors.cream,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Post',
            style: TextStyle(color: FlockColors.darkGreen)),
        content: const Text(
            'This will permanently delete the post and all replies.',
            style: TextStyle(color: FlockColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: FlockColors.midGreen)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await controller.deletePost(postId);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _friendlyErrorMessage(Object? error) {
    final raw = (error ?? '').toString().toLowerCase();
    if (raw.contains('permission-denied') ||
        raw.contains('missing or insufficient permissions')) {
      return 'You do not have access to view posts right now.\nPlease sign in again or check your account permissions.';
    }
    if (raw.contains('unauthenticated')) {
      return 'You are signed out.\nPlease sign in to view forum posts.';
    }
    if (raw.contains('unavailable') ||
        raw.contains('network') ||
        raw.contains('failed to get document') ||
        raw.contains('offline')) {
      return 'Unable to reach the database right now.\nPlease check your connection and try again.';
    }
    return 'Something went wrong while loading posts.\nPlease try again.';
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: FlockColors.tan),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: FlockColors.textSecondary, height: 1.5, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5E8D8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Color(0xFF8B2E00), size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFF8B2E00), fontSize: 13))),
        TextButton(
          onPressed: onDismiss,
          child: const Text('Dismiss',
              style: TextStyle(color: Color(0xFF8B2E00))),
        ),
      ]),
    );
  }
}