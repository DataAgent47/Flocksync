import 'package:flutter/material.dart';
import '../../../models/forum_post.dart';
import '../../../core/theme/flock_theme.dart';
// ─── Single category chip ──────────────────────────────────────────────────────

class CategoryChip extends StatelessWidget {
  final PostCategory category;
  final bool compact;

  const CategoryChip(
      {super.key, required this.category, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final meta = _categoryMeta[category]!;

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

// ─── Filter bar ────────────────────────────────────────────────────────────────

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
      height: 52,
      decoration: const BoxDecoration(
        color: FlockColors.cream,
        border: Border(
            bottom: BorderSide(color: FlockColors.divider, width: 1)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterPill(
              label: 'All',
              icon: Icons.apps_rounded,
              isSelected: selected == null,
              onTap: () => onSelected(null),
            ),
          ),
          ...PostCategory.values.map((cat) {
            final meta = _categoryMeta[cat]!;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterPill(
                label: meta.label,
                icon: meta.icon,
                isSelected: selected == cat,
                onTap: () => onSelected(selected == cat ? null : cat),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? FlockColors.darkGreen : FlockColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? FlockColors.darkGreen : FlockColors.tan,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13,
                color: isSelected ? FlockColors.cream : FlockColors.midGreen),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? FlockColors.cream : FlockColors.darkGreen,
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Category metadata ─────────────────────────────────────────────────────────

class _CategoryMeta {
  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;
  final Color border;
  const _CategoryMeta({required this.label, required this.icon,
      required this.fg, required this.bg, required this.border});
}

const _categoryMeta = {
  PostCategory.announcement: _CategoryMeta(
    label: 'Announcement', icon: Icons.campaign_outlined,
    fg: Color(0xFF0A400C), bg: Color(0xFFD8E8D8), border: Color(0xFF819067),
  ),
  PostCategory.maintenance: _CategoryMeta(
    label: 'Maintenance', icon: Icons.build_outlined,
    fg: Color(0xFF5C3A00), bg: Color(0xFFF0E4C8), border: Color(0xFFB1AB86),
  ),
  PostCategory.general: _CategoryMeta(
    label: 'General', icon: Icons.chat_outlined,
    fg: Color(0xFF0A400C), bg: Color(0xFFE8EDD8), border: Color(0xFF819067),
  ),
  PostCategory.question: _CategoryMeta(
    label: 'Question', icon: Icons.help_outline,
    fg: Color(0xFF2A4A0C), bg: Color(0xFFDDE8CC), border: Color(0xFF819067),
  ),
  PostCategory.marketplace: _CategoryMeta(
    label: 'Marketplace', icon: Icons.storefront_outlined,
    fg: Color(0xFF3D3000), bg: Color(0xFFECE8C8), border: Color(0xFFB1AB86),
  ),
};