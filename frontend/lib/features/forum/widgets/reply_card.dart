import 'package:flutter/material.dart';
import '../../../models/forum_reply.dart';
import '../../../core/theme/flock_theme.dart';
import 'image_grid.dart';

class ReplyCard extends StatelessWidget {
  final ForumReply reply;
  final String currentUserId;
  final bool isManagement;
  final VoidCallback onUpvote;
  final VoidCallback? onDelete;

  const ReplyCard({
    super.key,
    required this.reply,
    required this.currentUserId,
    required this.isManagement,
    required this.onUpvote,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUpvoted = reply.isUpvotedBy(currentUserId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: FlockColors.midGreen,
            backgroundImage: reply.authorAvatarUrl.isNotEmpty
                ? NetworkImage(reply.authorAvatarUrl)
                : null,
            child: reply.authorAvatarUrl.isEmpty
                ? Text(reply.authorName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 13,
                        color: FlockColors.cream,
                        fontWeight: FontWeight.w600))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  Text(reply.authorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: FlockColors.textPrimary)),
                  const SizedBox(width: 6),
                  Text(_formatDate(reply.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: FlockColors.textMuted)),
                  const Spacer(),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline,
                          size: 15, color: FlockColors.tan),
                    ),
                ]),

                const SizedBox(height: 5),

                // Bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FlockColors.cardBackground,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: FlockColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reply.body,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: FlockColors.textPrimary)),
                      if (reply.imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ImageGrid(imageUrls: reply.imageUrls),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                // Like
                GestureDetector(
                  onTap: onUpvote,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 13,
                        color: isUpvoted
                            ? FlockColors.darkGreen
                            : FlockColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reply.upvoteCount > 0 ? '${reply.upvoteCount}' : 'Like',
                        style: TextStyle(
                            fontSize: 12,
                            color: isUpvoted
                                ? FlockColors.darkGreen
                                : FlockColors.textMuted),
                      ),
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}