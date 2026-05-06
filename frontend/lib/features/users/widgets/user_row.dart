import 'package:flutter/material.dart';
import 'package:flocksync/core/theme/flock_theme.dart';
import 'package:flocksync/models/building_user.dart';
import '../services/users_service.dart';

class UserRow extends StatefulWidget {
  final BuildingUser user;
  final String currentUserId;
  final String propertyId;
  final bool isManagement;
  final UsersService service;

  const UserRow({
    super.key,
    required this.user,
    required this.currentUserId,
    required this.propertyId,
    required this.isManagement,
    required this.service,
  });

  @override
  State<UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<UserRow> with TickerProviderStateMixin {
  bool _expanded = false;
  bool _loading = false;
  bool? _viewVerified;

  // Effective verification status so that the UI updates when we verify a user
  bool get _effectiveIsVerified => _viewVerified ?? widget.user.isVerified;
  @override
  void didUpdateWidget(covariant UserRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.isVerified != widget.user.isVerified) {
      _viewVerified = null;
    }
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  Future<void> _onVerifyToggle() async {
    final targetVerified = !_effectiveIsVerified;
    setState(() => _loading = true);
    try {
      await widget.service.setVerificationStatus(
        userId: widget.user.userId,
        propertyId: widget.propertyId,
        role: widget.user.role,
        isVerified: targetVerified,
      );
      setState(() => _viewVerified = targetVerified);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _onRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove user'),
        content: const Text('Are you sure you want to remove this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    /// TODO implement removal of user
    setState(() => _loading = false);
  }

  void _onEdit() {
    // TODO: wire up edit flow
  }

  void _onMessage() {
    // TODO: wire up message flow
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = widget.user.userId == widget.currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Material(
          color: _effectiveIsVerified
              ? FlockColors.cardBackground
              : Color.alphaBlend(
                  const Color(0x26C62828),
                  FlockColors.cardBackground,
                ),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _toggle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _effectiveIsVerified
                      ? FlockColors.divider
                      : const Color(0xFF8B2E00),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: FlockColors.tan,
                        ),
                        child: widget.user.photoUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  widget.user.photoUrl,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.fullName,
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
                                  widget.user.apartmentNumber.isEmpty
                                      ? 'No apartment'
                                      : widget.user.apartmentNumber,
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
                      if (!_effectiveIsVerified) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleBadgeColor(),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.user.roleLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FlockColors.cream,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 12),
                    if (widget.user.email != null && widget.user.email!.isNotEmpty) ...[
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 12,
                          color: FlockColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        widget.user.email!,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.user.phoneNumber != null &&
                        widget.user.phoneNumber!.isNotEmpty) ...[
                      const Text(
                        'Phone',
                        style: TextStyle(
                          fontSize: 12,
                          color: FlockColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        widget.user.phoneNumber!,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (!isSelf) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (widget.isManagement && !_effectiveIsVerified)
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _onVerifyToggle,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FlockColors.darkGreen,
                                  foregroundColor: FlockColors.cream,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: FlockColors.cream,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Verify'),
                              ),
                            ),
                          if (widget.isManagement)
                            SizedBox(
                              height: 40,
                              child: OutlinedButton(
                                onPressed: _loading ? null : _onEdit,
                                child: const Text('Edit Details'),
                              ),
                            ),
                          if (widget.isManagement)
                            SizedBox(
                              height: 40,
                              child: OutlinedButton(
                                onPressed: _loading ? null : _onRemove,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                ),
                                child: const Text('Remove User'),
                              ),
                            ),
                          SizedBox(
                            height: 40,
                            child: OutlinedButton(
                              onPressed: _loading ? null : _onMessage,
                              child: const Text('Message User'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleBadgeColor() {
    if (widget.user.role == 'manager') {
      if (widget.user.managerRole == 'Building Owner') {
        return const Color(0xFF2E7D32);
      }
      return const Color(0xFF1565C0);
    }

    return const Color(0xFF00897B);
  }
}
