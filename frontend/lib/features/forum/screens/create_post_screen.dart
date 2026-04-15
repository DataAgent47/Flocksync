import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/forum_controller.dart';
import '../../../core/theme/flock_theme.dart';
import '../../../models/forum_post.dart';
import '../widgets/category_chip.dart';

class CreatePostScreen extends StatefulWidget {
  final String buildingId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatarUrl;

  const CreatePostScreen({
    super.key,
    required this.buildingId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatarUrl = '',
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imagePicker = ImagePicker();

  PostCategory _selectedCategory = PostCategory.general;
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _imagePicker.pickMultiImage(imageQuality: 75);
    if (picked.isNotEmpty) {
      setState(() => _selectedImages.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.buildingId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your building is still loading. Please wait, then try posting again.',
          ),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final controller = context.read<ForumController>();
    final postId = await controller.createPost(
      authorId: widget.currentUserId,
      authorName: widget.currentUserName,
      authorAvatarUrl: widget.currentUserAvatarUrl,
      buildingId: widget.buildingId,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      category: _selectedCategory,
      imageFiles: List.from(_selectedImages),
    );
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (postId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully.')),
        );
        Navigator.pop(context);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Failed to create post.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlockColors.cream,
      appBar: AppBar(
        backgroundColor: FlockColors.cream,
        title: const Text('New Post',
            style: TextStyle(
                color: FlockColors.darkGreen, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: FlockColors.darkGreen),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isSubmitting
                ? const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: FlockColors.darkGreen)))
                : FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: FlockColors.darkGreen,
                      foregroundColor: FlockColors.cream,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Post',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Category ────────────────────────────────────────────────
            const Text('Category',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: FlockColors.darkGreen,
                    fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PostCategory.values.map((cat) {
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? FlockColors.darkGreen
                          : FlockColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? FlockColors.darkGreen
                            : FlockColors.tan,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Use the chip but override colors via selected state
                        if (!selected) CategoryChip(category: cat, compact: true)
                        else Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_catIcon(cat), size: 13, color: FlockColors.cream),
                          const SizedBox(width: 4),
                          Text(_catLabel(cat),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: FlockColors.cream,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Title ───────────────────────────────────────────────────
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: FlockColors.darkGreen),
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: "What's this about?",
                labelStyle:
                    const TextStyle(color: FlockColors.midGreen),
                hintStyle: const TextStyle(color: FlockColors.textMuted),
                filled: true,
                fillColor: FlockColors.cardBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: FlockColors.tan)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: FlockColors.tan)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: FlockColors.darkGreen, width: 1.5)),
              ),
              maxLength: 120,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please add a title'
                  : null,
            ),

            const SizedBox(height: 16),

            // ── Body ────────────────────────────────────────────────────
            TextFormField(
              controller: _bodyController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 8,
              maxLength: 2000,
              style: const TextStyle(color: FlockColors.darkGreen),
              decoration: InputDecoration(
                labelText: 'Details',
                hintText: 'Add more context, questions, or information…',
                alignLabelWithHint: true,
                labelStyle:
                    const TextStyle(color: FlockColors.midGreen),
                hintStyle: const TextStyle(color: FlockColors.textMuted),
                filled: true,
                fillColor: FlockColors.cardBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: FlockColors.tan)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: FlockColors.tan)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: FlockColors.darkGreen, width: 1.5)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please add some details'
                  : null,
            ),

            const SizedBox(height: 24),

            // ── Photos ──────────────────────────────────────────────────
            Row(children: [
              const Text('Photos',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: FlockColors.darkGreen,
                      fontSize: 13)),
              const SizedBox(width: 6),
              const Text('optional',
                  style: TextStyle(
                      fontSize: 11, color: FlockColors.textMuted)),
            ]),
            const SizedBox(height: 10),

            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, i) {
                  if (i == _selectedImages.length) {
                    return _AddPhotoTile(onTap: _pickImages);
                  }
                  return _PhotoPreviewTile(
                    file: _selectedImages[i],
                    onRemove: () =>
                        setState(() => _selectedImages.removeAt(i)),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  IconData _catIcon(PostCategory cat) {
    const icons = {
      PostCategory.announcement: Icons.campaign_outlined,
      PostCategory.maintenance: Icons.build_outlined,
      PostCategory.general: Icons.chat_outlined,
      PostCategory.question: Icons.help_outline,
      PostCategory.marketplace: Icons.storefront_outlined,
    };
    return icons[cat]!;
  }

  String _catLabel(PostCategory cat) {
    const labels = {
      PostCategory.announcement: 'Announcement',
      PostCategory.maintenance: 'Maintenance',
      PostCategory.general: 'General',
      PostCategory.question: 'Question',
      PostCategory.marketplace: 'Marketplace',
    };
    return labels[cat]!;
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: FlockColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FlockColors.tan),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  color: FlockColors.midGreen, size: 26),
              SizedBox(height: 4),
              Text('Add photo',
                  style: TextStyle(
                      fontSize: 11,
                      color: FlockColors.midGreen,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPreviewTile extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _PhotoPreviewTile({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 13, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }
}