import 'package:flutter/material.dart';
import '../../../models/forum_post.dart';
import '../../../core/theme/flock_theme.dart';
import '../../../core/widgets/verification_badge.dart';
import 'category_chip.dart';

class PostCard extends StatelessWidget {
  final ForumPost post;
  final String currentUserId;
  final bool isManagement;
  final VoidCallback onTap;
  final VoidCallback onUpvote;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.isManagement,
    required this.onTap,
    required this.onUpvote,
    this.onDelete,
    this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final isUpvoted = post.isUpvotedBy(currentUserId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: FlockColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: post.isPinned
                ? FlockColors.midGreen
                : FlockColors.divider,
            width: post.isPinned ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row ─────────────────────────────────────────────
              Row(
                children: [
                  if (post.isPinned) ...[
                    const Icon(Icons.push_pin,
                        size: 13, color: FlockColors.midGreen),
                    const SizedBox(width: 4),
                    const Text('Pinned',
                        style: TextStyle(
                            fontSize: 11,
                            color: FlockColors.midGreen,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                  ],
                  CategoryChip(category: post.category, compact: true),
                  const Spacer(),
                  Text(_formatDate(post.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: FlockColors.textMuted)),
                  if (onDelete != null || onPin != null)
                    _OverflowMenu(
                        isPinned: post.isPinned,
                        onDelete: onDelete,
                        onPin: onPin),
                ],
              ),

              const SizedBox(height: 10),

              // ── Title ───────────────────────────────────────────────
              Text(post.title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: FlockColors.textPrimary,
                      height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),

              const SizedBox(height: 5),

              // ── Body preview ─────────────────────────────────────────
              Text(post.body,
                  style: const TextStyle(
                      fontSize: 14,
                      color: FlockColors.textSecondary,
                      height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),

              // ── Image indicator ──────────────────────────────────────
              if (post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.image_outlined,
                      size: 13, color: FlockColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${post.imageUrls.length} photo${post.imageUrls.length > 1 ? "s" : ""}',
                    style: const TextStyle(
                        fontSize: 12, color: FlockColors.textMuted),
                  ),
                ]),
              ],

              const SizedBox(height: 12),
              const Divider(color: FlockColors.divider, height: 1),
              const SizedBox(height: 10),

              // ── Footer ───────────────────────────────────────────────
              Row(children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: FlockColors.midGreen,
                  backgroundImage: post.authorAvatarUrl.isNotEmpty
                      ? NetworkImage(post.authorAvatarUrl)
                      : null,
                  child: post.authorAvatarUrl.isEmpty
                      ? Text(post.authorName[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11,
                              color: FlockColors.cream,
                              fontWeight: FontWeight.w600))
                      : null,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.authorName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: FlockColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      VerificationBadge(
                        isVerified: post.authorIsVerified,
                        role: post.authorRole,
                      ),
                    ],
                  ),
                ),
                // Upvote
                GestureDetector(
                  onTap: onUpvote,
                  child: Row(children: [
                    Icon(
                      isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 15,
                      color: isUpvoted
                          ? FlockColors.darkGreen
                          : FlockColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.upvoteCount}',
                        style: TextStyle(
                            fontSize: 12,
                            color: isUpvoted
                                ? FlockColors.darkGreen
                                : FlockColors.textMuted)),
                  ]),
                ),
                const SizedBox(width: 14),
                // Replies
                Row(children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 15, color: FlockColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${post.replyCount}',
                      style: const TextStyle(
                          fontSize: 12, color: FlockColors.textMuted)),
                ]),
              ]),
            ],
          ),
        ),
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
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _OverflowMenu extends StatelessWidget {
  final bool isPinned;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;

  const _OverflowMenu({required this.isPinned, this.onDelete, this.onPin});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: FlockColors.textMuted),
      color: FlockColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        if (onPin != null)
          PopupMenuItem(
            value: 'pin',
            child: Row(children: [
              Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  size: 18, color: FlockColors.midGreen),
              const SizedBox(width: 8),
              Text(isPinned ? 'Unpin' : 'Pin to top',
                  style: const TextStyle(color: FlockColors.darkGreen)),
            ]),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline,
                  size: 18, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red.shade700)),
            ]),
          ),
      ],
      onSelected: (v) {
        if (v == 'pin') onPin?.call();
        if (v == 'delete') onDelete?.call();
      },
    );
  }
}