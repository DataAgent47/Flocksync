import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/forum_controller.dart';
import '../../../../core/theme/flock_theme.dart';
import '../../../../models/forum_post.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

class AnnouncementsScreen extends StatelessWidget {
  final String buildingId;
  final ForumType forumType;
  final String forumKey;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatarUrl;
  final bool isManagement;
  final PostCategory category;
  final String title;

  const AnnouncementsScreen({
    super.key,
    required this.buildingId,
    required this.forumType,
    required this.forumKey,
    required this.currentUserId,
    required this.currentUserName,
    required this.category,
    required this.title,
    this.currentUserAvatarUrl = '',
    this.isManagement = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForumController(
        forumType: forumType,
        forumKey: forumKey,
      ),
      child: _AnnouncementsView(
        buildingId: buildingId,
        forumType: forumType,
        forumKey: forumKey,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserAvatarUrl: currentUserAvatarUrl,
        isManagement: isManagement,
        category: category,
        title: title,
      ),
    );
  }
}

class _AnnouncementsView extends StatelessWidget {
  final String buildingId;
  final ForumType forumType;
  final String forumKey;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatarUrl;
  final bool isManagement;
  final PostCategory category;
  final String title;

  const _AnnouncementsView({
    required this.buildingId,
    required this.forumType,
    required this.forumKey,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatarUrl,
    required this.isManagement,
    required this.category,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ForumController>();

    return Scaffold(
      backgroundColor: FlockColors.cream,

      appBar: AppBar(
        title: Text(title),
        backgroundColor: FlockColors.cream,
        elevation: 0,
      ),

      body: StreamBuilder<List<ForumPost>>(
        stream: controller.postsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load announcements.',
                style: TextStyle(color: FlockColors.textSecondary),
              ),
            );
          }

          final allPosts = snapshot.data ?? [];

          // Filter only one category.
          final filteredPosts = allPosts
              .where(
                (post) => post.category == category,
              )
              .toList();

          if (filteredPosts.isEmpty) {
            return Center(
              child: Text('No $title yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredPosts.length,
            itemBuilder: (context, index) {
              final post = filteredPosts[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PostCard(
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
                          forumType: forumType,
                          currentUserId: currentUserId,
                          currentUserName: currentUserName,
                          currentUserAvatarUrl:
                              currentUserAvatarUrl,
                          isManagement: isManagement,
                        ),
                      ),
                    ),
                  ),

                  onUpvote: () => controller.togglePostUpvote(
                    post.id,
                    currentUserId,
                  ),

                  onDelete:
                      isManagement || post.authorId == currentUserId
                          ? () => controller.deletePost(post.id)
                          : null,

                  onPin: isManagement
                      ? () => controller.togglePin(
                            post.id,
                            !post.isPinned,
                          )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}