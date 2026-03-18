import 'package:flutter/material.dart';
import '../../../models/forum_post.dart';
import '../../../core/theme/flock_theme.dart';

class CategoryFilterBar extends StatelessWidget {
  final PostCategory? selected;
  final void Function(PostCategory?) onSelected;

  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: FlockColors.cream,
        border: Border(
          bottom: BorderSide(color: FlockColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── All Posts button ─────────────────────────────────────────
          GestureDetector(
            onTap: () => onSelected(null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected == null
                    ? FlockColors.darkGreen
                    : FlockColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected == null
                      ? FlockColors.darkGreen
                      : FlockColors.tan,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 14,
                    color: selected == null
                        ? FlockColors.cream
                        : FlockColors.midGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'All Posts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected == null
                          ? FlockColors.cream
                          : FlockColors.darkGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ── Active category label (shows when a filter is selected) ──
          if (selected != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                _categoryLabel(selected!),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: FlockColors.textSecondary,
                ),
              ),
            ),

          // ── Hamburger menu ───────────────────────────────────────────
          GestureDetector(
            onTap: () => _openCategorySheet(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected != null
                    ? FlockColors.darkGreen
                    : FlockColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected != null
                      ? FlockColors.darkGreen
                      : FlockColors.tan,
                ),
              ),
              child: Icon(
                Icons.tune,
                size: 18,
                color: selected != null
                    ? FlockColors.cream
                    : FlockColors.midGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlockColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CategorySheet(
        selected: selected,
        onSelected: (cat) {
          Navigator.pop(ctx);
          onSelected(cat);
        },
      ),
    );
  }

  String _categoryLabel(PostCategory cat) {
    return switch (cat) {
      PostCategory.announcement => 'Announcements',
      PostCategory.maintenance => 'Maintenance',
      PostCategory.general => 'General',
      PostCategory.question => 'Questions',
      PostCategory.marketplace => 'Marketplace',
    };
  }
}

// ─── Bottom sheet category picker ─────────────────────────────────────────────

class _CategorySheet extends StatelessWidget {
  final PostCategory? selected;
  final void Function(PostCategory?) onSelected;

  const _CategorySheet({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: FlockColors.tan,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Filter by Category',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: FlockColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),

          // Category tiles
          ..._categoryItems.map(
            (item) => _CategoryTile(
              icon: item.icon,
              label: item.label,
              isSelected: selected == item.category,
              onTap: () => onSelected(item.category),
            ),
          ),

          const SizedBox(height: 8),

          // Clear filter
          if (selected != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => onSelected(null),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FlockColors.darkGreen,
                  side: const BorderSide(color: FlockColors.tan),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Clear Filter',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? FlockColors.darkGreen : FlockColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? FlockColors.darkGreen : FlockColors.tan,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? FlockColors.cream : FlockColors.midGreen,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? FlockColors.cream : FlockColors.darkGreen,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check, size: 18, color: FlockColors.cream),
          ],
        ),
      ),
    );
  }
}

// ─── Category metadata ─────────────────────────────────────────────────────────

class _CategoryItem {
  final PostCategory category;
  final String label;
  final IconData icon;
  const _CategoryItem(
      {required this.category, required this.label, required this.icon});
}

const _categoryItems = [
  _CategoryItem(
    category: PostCategory.announcement,
    label: 'Announcements',
    icon: Icons.campaign_outlined,
  ),
  _CategoryItem(
    category: PostCategory.maintenance,
    label: 'Maintenance',
    icon: Icons.build_outlined,
  ),
  _CategoryItem(
    category: PostCategory.general,
    label: 'General',
    icon: Icons.chat_outlined,
  ),
  _CategoryItem(
    category: PostCategory.question,
    label: 'Questions',
    icon: Icons.help_outline,
  ),
  _CategoryItem(
    category: PostCategory.marketplace,
    label: 'Marketplace',
    icon: Icons.storefront_outlined,
  ),
];


// ─── Single category chip (used on post cards and detail screen) ───────────────

class CategoryChip extends StatelessWidget {
  final PostCategory category;
  final bool compact;

  const CategoryChip(
      {super.key, required this.category, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final meta = _chipMeta[category]!;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: meta.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: meta.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: compact ? 11 : 13, color: meta.fg),
          const SizedBox(width: 4),
          Text(
            meta.label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              color: meta.fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipMeta {
  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;
  final Color border;
  const _ChipMeta({
    required this.label,
    required this.icon,
    required this.fg,
    required this.bg,
    required this.border,
  });
}

const _chipMeta = {
  PostCategory.announcement: _ChipMeta(
    label: 'Announcement',
    icon: Icons.campaign_outlined,
    fg: Color(0xFF0A400C),
    bg: Color(0xFFD8E8D8),
    border: Color(0xFF819067),
  ),
  PostCategory.maintenance: _ChipMeta(
    label: 'Maintenance',
    icon: Icons.build_outlined,
    fg: Color(0xFF5C3A00),
    bg: Color(0xFFF0E4C8),
    border: Color(0xFFB1AB86),
  ),
  PostCategory.general: _ChipMeta(
    label: 'General',
    icon: Icons.chat_outlined,
    fg: Color(0xFF0A400C),
    bg: Color(0xFFE8EDD8),
    border: Color(0xFF819067),
  ),
  PostCategory.question: _ChipMeta(
    label: 'Question',
    icon: Icons.help_outline,
    fg: Color(0xFF2A4A0C),
    bg: Color(0xFFDDE8CC),
    border: Color(0xFF819067),
  ),
  PostCategory.marketplace: _ChipMeta(
    label: 'Marketplace',
    icon: Icons.storefront_outlined,
    fg: Color(0xFF3D3000),
    bg: Color(0xFFECE8C8),
    border: Color(0xFFB1AB86),
  ),
};