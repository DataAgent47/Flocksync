import 'package:flutter/material.dart';
import '../theme/flock_theme.dart';

/// Small inline badge shown next to a user's name indicating their
/// verification status and role at the time of the action.
///
/// Usage on posts:
///   VerificationBadge(
///     isVerified: post.authorIsVerified,
///     role: post.authorRole,
///   )
///
/// Usage on settings screen (live, from Firestore):
///   VerificationBadge(
///     isVerified: profile.isVerified,
///     role: profile.role,
///   )
class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  /// Role label. Accepts 'resident', 'manager', or 'management'.
  final String role;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final label = _label();
    final colors = _colors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_outlined : Icons.schedule_outlined,
            size: 10,
            color: colors.foreground,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  String _label() {
    final verification = isVerified ? 'Verified' : 'Unverified';
    final normalizedRole = role.trim().toLowerCase();
    final isManagementRole =
        normalizedRole == 'management' || normalizedRole == 'manager';
    final roleLabel = isManagementRole ? 'Management' : 'Resident';
    return '$verification $roleLabel';
  }

  _BadgeColors _colors() {
    final normalizedRole = role.trim().toLowerCase();
    final isManagementRole =
        normalizedRole == 'management' || normalizedRole == 'manager';
    if (isVerified && isManagementRole) {
      // Verified management — dark green, stands out
      return _BadgeColors(
        background: FlockColors.darkGreen.withOpacity(0.1),
        border: FlockColors.darkGreen.withOpacity(0.4),
        foreground: FlockColors.darkGreen,
      );
    }
    if (isVerified) {
      // Verified resident — mid green
      return _BadgeColors(
        background: FlockColors.midGreen.withOpacity(0.12),
        border: FlockColors.midGreen.withOpacity(0.4),
        foreground: FlockColors.midGreen,
      );
    }
    // Unverified — muted tan, doesn't compete with content
    return _BadgeColors(
      background: FlockColors.tan.withOpacity(0.2),
      border: FlockColors.tan,
      foreground: FlockColors.textMuted,
    );
  }
}

class _BadgeColors {
  final Color background;
  final Color border;
  final Color foreground;
  const _BadgeColors({
    required this.background,
    required this.border,
    required this.foreground,
  });
}