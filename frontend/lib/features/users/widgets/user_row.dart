import 'package:flutter/material.dart';
import 'package:flocksync/core/theme/flock_theme.dart';
import 'package:flocksync/models/building_user.dart';
import '../../../features/messaging/screens/chat_screen.dart';
import '../services/users_service.dart';

class UserRow extends StatefulWidget {
  final BuildingUser user;
  final String currentUserId;
  final String currentUserName;
  final String propertyId;
  final bool isManagement;
  final bool showDeletedUser;
  final UsersService service;

  const UserRow({
    super.key,
    required this.user,
    required this.currentUserId,
    required this.currentUserName,
    required this.propertyId,
    required this.isManagement,
    this.showDeletedUser = false,
    required this.service,
  });

  @override
  State<UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<UserRow> with TickerProviderStateMixin {
  bool _expanded = false;
  bool _loading = false;
  bool? _viewVerified;
  String? _viewFirstName;
  String? _viewLastName;
  String? _viewApartment;
  String? _viewManagerRole;
  bool? _viewRejected;

  static const List<String> _managerRoles = [
    'Building Owner',
    'Superintendant',
    'Porter',
    'Doorman',
    'Building Manager',
  ];

  bool get _effectiveIsVerified => _viewVerified ?? widget.user.isVerified;
  bool get _effectiveIsRejected => _viewRejected ?? widget.user.verifiedRejected;
  String get _effectiveFirstName => _viewFirstName ?? widget.user.firstName;
  String get _effectiveLastName => _viewLastName ?? widget.user.lastName;
  String get _effectiveApartment => _viewApartment ?? widget.user.apartmentNumber;
  String? get _effectiveManagerRole => _viewManagerRole ?? widget.user.managerRole;
  String get _effectiveFullName => '$_effectiveFirstName $_effectiveLastName'.trim();

  @override
  void didUpdateWidget(covariant UserRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.isVerified != widget.user.isVerified) {
      _viewVerified = null;
    }
    if (oldWidget.user.verifiedRejected != widget.user.verifiedRejected) {
      _viewRejected = null;
    }
    if (oldWidget.user.firstName != widget.user.firstName ||
        oldWidget.user.lastName != widget.user.lastName ||
        oldWidget.user.apartmentNumber != widget.user.apartmentNumber ||
        oldWidget.user.managerRole != widget.user.managerRole) {
      _viewFirstName = null;
      _viewLastName = null;
      _viewApartment = null;
      _viewManagerRole = null;
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
      if (!mounted) {
        return;
      }
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await widget.service.removeUser(
        userId: widget.user.userId,
        propertyId: widget.propertyId,
        role: widget.user.role,
      );
      if (!mounted) {
        return;
      }
      setState(() => _viewRejected = true);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _onRestore() async {
    setState(() => _loading = true);
    try {
      await widget.service.restoreUser(
        userId: widget.user.userId,
        propertyId: widget.propertyId,
        role: widget.user.role,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _viewRejected = false;
        _viewVerified = true;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _onEdit() {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: _effectiveFirstName);
    final lastNameController = TextEditingController(text: _effectiveLastName);
    final apartmentController = TextEditingController(text: _effectiveApartment);
    final managerRoleController = TextEditingController(
      text: _effectiveManagerRole ?? '',
    );
    String? savedFirstName;
    String? savedLastName;
    String? savedApartment;
    String? savedManagerRole;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isSaving = false;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setDialogState(() {
                isSaving = true;
                errorText = null;
              });

              try {
                await widget.service.updateUserDetails(
                  userId: widget.user.userId,
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  apartmentNumber: apartmentController.text,
                  managerRole: widget.user.role == 'manager'
                      ? managerRoleController.text
                      : null,
                  role: widget.user.role,
                );

                savedFirstName = firstNameController.text.trim();
                savedLastName = lastNameController.text.trim();
                savedApartment = apartmentController.text.trim();
                savedManagerRole = widget.user.role == 'manager'
                    ? managerRoleController.text.trim()
                    : null;

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop();
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                  errorText = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return AlertDialog(
              title: const Text('Edit User Details'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (errorText != null) ...[
                        Text(
                          errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextFormField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'First name is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Last name is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: apartmentController,
                        decoration: const InputDecoration(
                          labelText: 'Apartment Number',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                      if (widget.user.role == 'manager') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue:
                              _managerRoleValue(managerRoleController.text),
                          decoration: const InputDecoration(
                            labelText: 'Manager Role',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: _managerRoles
                              .map(
                                (role) => DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(role),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    managerRoleController.text = value ?? '';
                                  });
                                },
                          validator: (value) {
                            if (widget.user.role == 'manager' &&
                                (value ?? '').trim().isEmpty) {
                              return 'Manager role is required.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlockColors.darkGreen,
                    foregroundColor: FlockColors.cream,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: FlockColors.cream,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      firstNameController.dispose();
      lastNameController.dispose();
      apartmentController.dispose();
      managerRoleController.dispose();
    }).then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (savedFirstName != null) {
          _viewFirstName = savedFirstName;
        }
        if (savedLastName != null) {
          _viewLastName = savedLastName;
        }
        if (savedApartment != null) {
          _viewApartment = savedApartment;
        }
        if (widget.user.role == 'manager' && savedManagerRole != null) {
          _viewManagerRole = savedManagerRole;
        }
      });
    });
  }

  void _onMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
            otherUser: widget.user,
            currentUserId: widget.currentUserId,
          ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_effectiveIsRejected && !widget.showDeletedUser) {
      return const SizedBox.shrink();
    }

    final isSelf = widget.user.userId == widget.currentUserId;
    final isRejectedView = widget.showDeletedUser && _effectiveIsRejected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Material(
          color: _effectiveIsVerified
              ? FlockColors.cardBackground
              : Color.alphaBlend(const Color(0x26C62828), FlockColors.cardBackground),
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
                  color: _effectiveIsVerified ? FlockColors.divider : const Color(0xFF8B2E00),
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
                                    return const Icon(Icons.person, color: FlockColors.darkGreen);
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
                              _effectiveFullName,
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
                                Builder(builder: (ctx) {
                                  final isSelf = widget.user.userId == widget.currentUserId;
                                  final apartment = _effectiveApartment;
                                  String label;
                                  if (apartment.isEmpty) {
                                    label = 'No apartment';
                                  } else if (isSelf || widget.isManagement || !widget.user.hideApartmentNumber) {
                                    label = apartment;
                                  } else {
                                    label = 'Hidden';
                                  }

                                  return Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: FlockColors.textSecondary,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isRejectedView) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Deleted',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: FlockColors.cream,
                            ),
                          ),
                        ),
                      ] else if (!_effectiveIsVerified) ...[
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getRoleBadgeColor(),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                            widget.user.role == 'manager' &&
                                (_effectiveManagerRole ?? '').isNotEmpty
                              ? _effectiveManagerRole!
                              : widget.user.roleLabel,
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
                    if ((widget.user.email ?? '').isNotEmpty) ...[
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
                    if ((widget.user.phoneNumber ?? '').isNotEmpty) ...[
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
                          if (widget.isManagement && !isRejectedView && !_effectiveIsVerified)
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
                          if (widget.isManagement && isRejectedView)
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _onRestore,
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
                                    : const Text('Restore User'),
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
                          if (widget.isManagement && !isRejectedView)
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
                          if (widget.isManagement || !isRejectedView)
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

  String? _managerRoleValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return _managerRoles.contains(trimmed) ? trimmed : null;
  }
}

