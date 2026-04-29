import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/forum_controller.dart';
import '../../../core/theme/flock_theme.dart';
import '../../../models/forum_post.dart';
import '../../../models/forum_reply.dart';
import '../widgets/reply_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/image_grid.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatarUrl;
  final bool isManagement;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatarUrl = '',
    this.isManagement = false,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _imagePicker.pickMultiImage(imageQuality: 75);
    if (picked.isNotEmpty) {
      setState(() => _selectedImages.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _submitReply(ForumController controller) async {
    final text = _replyController.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;
    setState(() => _isSubmitting = true);

    final success = await controller.createReply(
      postId: widget.postId,
      authorId: widget.currentUserId,
      authorName: widget.currentUserName,
      authorAvatarUrl: widget.currentUserAvatarUrl,
      body: text,
      imageFiles: List.from(_selectedImages),
    );

    if (success && mounted) {
      _replyController.clear();
      setState(() => _selectedImages.clear());
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ForumController>();

    return Scaffold(
      backgroundColor: FlockColors.cream,
      appBar: AppBar(
        backgroundColor: FlockColors.cream,
        title: const Text('Discussion',
            style: TextStyle(
                color: FlockColors.darkGreen, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: FlockColors.darkGreen),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<ForumPost?>(
              stream: controller.postStream(widget.postId),
              builder: (context, postSnap) {
                if (postSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: FlockColors.midGreen));
                }
                final post = postSnap.data;
                if (post == null) {
                  return const Center(
                      child: Text('Post not found.',
                          style:
                              TextStyle(color: FlockColors.textSecondary)));
                }

                return StreamBuilder<List<ForumReply>>(
                  stream: controller.repliesStream(widget.postId),
                  builder: (context, replySnap) {
                    final replies = replySnap.data ?? [];

                    return ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _PostBody(
                          post: post,
                          currentUserId: widget.currentUserId,
                          isManagement: widget.isManagement,
                          onUpvote: () => controller.togglePostUpvote(
                              post.id, widget.currentUserId),
                          onPin: widget.isManagement
                              ? () => controller.togglePin(
                                  post.id, !post.isPinned)
                              : null,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '${post.replyCount} ${post.replyCount == 1 ? "Reply" : "Replies"}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: FlockColors.darkGreen),
                        ),
                        const SizedBox(height: 12),
                        if (replySnap.connectionState ==
                            ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: FlockColors.midGreen)),
                          )
                        else if (replies.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('No replies yet. Be the first!',
                                style: TextStyle(
                                    color: FlockColors.textSecondary,
                                    fontSize: 14)),
                          )
                        else
                          ...replies.map((reply) => ReplyCard(
                                reply: reply,
                                currentUserId: widget.currentUserId,
                                isManagement: widget.isManagement,
                                onUpvote: () => controller.toggleReplyUpvote(
                                    widget.postId,
                                    reply.id,
                                    widget.currentUserId),
                                onDelete: widget.isManagement ||
                                        reply.authorId == widget.currentUserId
                                    ? () => _confirmDeleteReply(
                                        context, controller, reply.id)
                                    : null,
                              )),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Reply composer ───────────────────────────────────────────────
          _ReplyComposer(
            controller: _replyController,
            selectedImages: _selectedImages,
            isSubmitting: _isSubmitting,
            onPickImages: _pickImages,
            onRemoveImage: (i) => setState(() => _selectedImages.removeAt(i)),
            onSubmit: () => _submitReply(controller),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteReply(
      BuildContext context, ForumController controller, String replyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FlockColors.cream,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Reply',
            style: TextStyle(color: FlockColors.darkGreen)),
        content: const Text('Delete this reply permanently?',
            style: TextStyle(color: FlockColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: FlockColors.midGreen))),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await controller.deleteReply(widget.postId, replyId);
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
}

// ─── Post body ─────────────────────────────────────────────────────────────────

class _PostBody extends StatelessWidget {
  final ForumPost post;
  final String currentUserId;
  final bool isManagement;
  final VoidCallback onUpvote;
  final VoidCallback? onPin;

  const _PostBody({
    required this.post,
    required this.currentUserId,
    required this.isManagement,
    required this.onUpvote,
    this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final isUpvoted = post.isUpvotedBy(currentUserId);

    return Container(
      decoration: BoxDecoration(
        color: FlockColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FlockColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author + category
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: FlockColors.midGreen,
              backgroundImage: post.authorAvatarUrl.isNotEmpty
                  ? NetworkImage(post.authorAvatarUrl)
                  : null,
              child: post.authorAvatarUrl.isEmpty
                  ? Text(post.authorName[0].toUpperCase(),
                      style: const TextStyle(
                          color: FlockColors.cream,
                          fontWeight: FontWeight.w600))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.authorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: FlockColors.darkGreen)),
                  Text(_formatDate(post.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: FlockColors.textMuted)),
                ],
              ),
            ),
            if (post.isPinned)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.push_pin,
                    size: 15, color: FlockColors.midGreen),
              ),
            CategoryChip(category: post.category, compact: true),
          ]),

          const SizedBox(height: 14),

          Text(post.title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: FlockColors.darkGreen,
                  height: 1.3)),
          const SizedBox(height: 8),
          Text(post.body,
              style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: FlockColors.textPrimary)),

          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            ImageGrid(imageUrls: post.imageUrls),
          ],

          const SizedBox(height: 14),
          const Divider(color: FlockColors.divider),
          const SizedBox(height: 8),

          // Actions
          Row(children: [
            _ActionBtn(
              icon: isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
              label: '${post.upvoteCount}',
              active: isUpvoted,
              onTap: onUpvote,
            ),
            if (onPin != null) ...[
              const SizedBox(width: 16),
              _ActionBtn(
                icon: post.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                label: post.isPinned ? 'Unpin' : 'Pin',
                active: post.isPinned,
                onTap: onPin!,
              ),
            ],
          ]),
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
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? FlockColors.darkGreen : FlockColors.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ─── Reply composer ────────────────────────────────────────────────────────────

class _ReplyComposer extends StatelessWidget {
  final TextEditingController controller;
  final List<File> selectedImages;
  final bool isSubmitting;
  final VoidCallback onPickImages;
  final void Function(int) onRemoveImage;
  final VoidCallback onSubmit;

  const _ReplyComposer({
    required this.controller,
    required this.selectedImages,
    required this.isSubmitting,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FlockColors.cream,
        border: Border(top: BorderSide(color: FlockColors.divider)),
      ),
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedImages.isNotEmpty)
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedImages.length,
                itemBuilder: (context, i) => Stack(children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                          image: FileImage(selectedImages[i]),
                          fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => onRemoveImage(i),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ]),
              ),
            ),

          if (selectedImages.isNotEmpty) const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onPickImages,
                icon: const Icon(Icons.image_outlined),
                color: FlockColors.midGreen,
                tooltip: 'Add photo',
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: FlockColors.darkGreen),
                  decoration: InputDecoration(
                    hintText: 'Write a reply…',
                    hintStyle: const TextStyle(color: FlockColors.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: FlockColors.cardBackground,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              isSubmitting
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: FlockColors.darkGreen)),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                          color: FlockColors.darkGreen,
                          shape: BoxShape.circle),
                      child: IconButton(
                        onPressed: onSubmit,
                        icon: const Icon(Icons.send,
                            color: FlockColors.cream, size: 18),
                        tooltip: 'Send reply',
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}