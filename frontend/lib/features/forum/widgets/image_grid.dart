import 'package:flutter/material.dart';
import '../../../core/theme/flock_theme.dart';

/// Displays a tappable grid of network images.
/// 1 image → full width. 2 images → side by side. 3+ → 2-col grid.
class ImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final double maxHeight;

  const ImageGrid({
    super.key,
    required this.imageUrls,
    this.maxHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (imageUrls.length == 1) {
      return _buildTile(context, imageUrls[0], 0, double.infinity, maxHeight);
    }

    if (imageUrls.length == 2) {
      return Row(
        children: [
          Expanded(
              child: _buildTile(context, imageUrls[0], 0, double.infinity, 160)),
          const SizedBox(width: 4),
          Expanded(
              child: _buildTile(context, imageUrls[1], 1, double.infinity, 160)),
        ],
      );
    }

    final displayCount = imageUrls.length > 4 ? 4 : imageUrls.length;
    final remaining = imageUrls.length - displayCount;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: displayCount,
      itemBuilder: (context, i) {
        final isLast = i == displayCount - 1 && remaining > 0;
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildTile(context, imageUrls[i], i, double.infinity, double.infinity),
            if (isLast)
              Container(
                decoration: BoxDecoration(
                  color: FlockColors.darkGreen.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: const TextStyle(
                        color: FlockColors.cream,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTile(BuildContext context, String url, int index,
      double width, double height) {
    return GestureDetector(
      onTap: () => _openGallery(context, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: width,
          height: height == double.infinity ? null : height,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Container(
                color: FlockColors.cardBackground,
                child: const Center(
                    child: CircularProgressIndicator(
                        color: FlockColors.midGreen, strokeWidth: 2)),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              color: FlockColors.cardBackground,
              child: const Icon(Icons.broken_image_outlined,
                  color: FlockColors.tan),
            ),
          ),
        ),
      ),
    );
  }

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _ImageGallery(imageUrls: imageUrls, initialIndex: initialIndex),
        fullscreenDialog: true,
      ),
    );
  }
}

// ─── Full-screen gallery ───────────────────────────────────────────────────────

class _ImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageGallery({required this.imageUrls, required this.initialIndex});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlockColors.darkGreen,
      appBar: AppBar(
        backgroundColor: FlockColors.darkGreen,
        foregroundColor: FlockColors.cream,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(
              color: FlockColors.cream,
              fontWeight: FontWeight.w600,
              fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: FlockColors.cream),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, i) => InteractiveViewer(
          child: Center(
            child: Image.network(
              widget.imageUrls[i],
              fit: BoxFit.contain,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return const Center(
                    child: CircularProgressIndicator(
                        color: FlockColors.tan));
              },
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_outlined,
                    color: FlockColors.tan, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}