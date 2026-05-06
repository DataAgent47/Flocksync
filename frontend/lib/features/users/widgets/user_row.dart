import 'package:flutter/material.dart';
import 'package:flocksync/core/theme/flock_theme.dart';
import 'package:flocksync/models/building_user.dart';

class UserRow extends StatelessWidget {
  final BuildingUser user;

  const UserRow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: user.isVerified
            ? FlockColors.cardBackground
            : Color.alphaBlend(
                const Color(0x26C62828),
                FlockColors.cardBackground,
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.isVerified ? FlockColors.divider : const Color(0xFF8B2E00),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FlockColors.tan,
            ),
            child: user.photoUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      user.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: FlockColors.darkGreen,
                        );
                      },
                    ),
                  )
                : const Icon(Icons.person, color: FlockColors.darkGreen),
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FlockColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 14,
                      color: FlockColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.apartmentNumber.isEmpty
                          ? 'No apartment'
                          : user.apartmentNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        color: FlockColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Verification badge (if unverified)
          if (!user.isVerified) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Unverified',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FlockColors.cream,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getRoleBadgeColor(),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              user.roleLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FlockColors.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleBadgeColor() {
    if (user.role == 'manager') {
      if (user.managerRole == 'Building Owner') {
        return const Color(0xFF2E7D32); // Dark green for owner
      }
      return const Color(0xFF1565C0); // Blue for other managers
    }
    return const Color(0xFF00897B); // Teal for residents
  }
}
