import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/flock_theme.dart';
import '../../../core/widgets/flock_message_banner.dart';
import '../controllers/settings_controller.dart';

class SecuritySettingsScreen extends StatefulWidget {
  final String uid;
  final User user;
  final SettingsController controller;

  const SecuritySettingsScreen({
    super.key,
    required this.uid,
    required this.user,
    required this.controller,
  });

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  String? _statusMessage;
  bool _statusIsError = false;
  String? _statusSection;

  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _newEmailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newEmailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<String?> _promptCurrentPassword() async {
    return showDialog<String?>(
      context: context,
      builder: (context) {
        final passwordController = TextEditingController();
        return AlertDialog(
          title: const Text('Password Required'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Current Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, passwordController.text);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeEmail() async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    String? currentPassword;
    if (widget.controller.requiresPasswordReauth) {
      currentPassword = await _promptCurrentPassword();
      if (!mounted || currentPassword == null) {
        return;
      }
    }

    setState(() {
      _statusMessage = null;
      _statusIsError = false;
      _statusSection = null;
    });

    final ok = await widget.controller.changeLoginEmail(
      uid: widget.uid,
      newEmail: _newEmailController.text,
      currentPassword: widget.controller.requiresPasswordReauth
          ? currentPassword
          : null,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      setState(() {
        _statusMessage = 'Email update initiated. Check your inbox.';
        _statusIsError = false;
        _statusSection = 'email';
      });
      _newEmailController.clear();
    } else {
      setState(() {
        _statusMessage = widget.controller.errorMessage ?? 'Action failed.';
        _statusIsError = true;
        _statusSection = 'email';
      });
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    String? currentPassword;
    if (widget.controller.requiresPasswordReauth) {
      currentPassword = await _promptCurrentPassword();
      if (!mounted || currentPassword == null) {
        return;
      }
    }

    setState(() {
      _statusMessage = null;
      _statusIsError = false;
      _statusSection = null;
    });

    final ok = await widget.controller.changePassword(
      newPassword: _newPasswordController.text,
      currentPassword: widget.controller.requiresPasswordReauth
          ? currentPassword
          : null,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      setState(() {
        _statusMessage = 'Password changed successfully.';
        _statusIsError = false;
        _statusSection = 'password';
      });
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } else {
      setState(() {
        _statusMessage = widget.controller.errorMessage ?? 'Action failed.';
        _statusIsError = true;
        _statusSection = 'password';
      });
    }
  }

  Future<void> _deleteAccount() async {
    final password = await showDialog<String?>(
      context: context,
      builder: (context) {
        final deletePasswordController = TextEditingController();
        return AlertDialog(
          title: const Text('Delete Account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will permanently remove your account data. This action cannot be undone.',
              ),
              if (widget.controller.requiresPasswordReauth) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: deletePasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, deletePasswordController.text);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || password == null) {
      return;
    }

    final ok = await widget.controller.deleteAccount(currentPassword: password);

    if (!mounted) {
      return;
    }

    if (!ok) {
      setState(() {
        _statusMessage = widget.controller.errorMessage ?? 'Delete failed.';
        _statusIsError = true;
        _statusSection = 'delete';
      });
      return;
    }

    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final isPasswordUser = widget.controller.requiresPasswordReauth;

        return Scaffold(
          appBar: AppBar(title: const Text('Security')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Login Provider',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: FlockColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPasswordUser ? 'Email and Password' : 'Google',
                    style: const TextStyle(color: FlockColors.textSecondary),
                  ),
                  if (isPasswordUser) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Change Login Email',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: FlockColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current: ${widget.user.email ?? 'Not available'}',
                      style: const TextStyle(color: FlockColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: _emailFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_statusMessage != null &&
                              _statusSection == 'email') ...[
                            FlockMessageBanner(
                              message: _statusMessage!,
                              isError: _statusIsError,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _newEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'New Login Email',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'New email is required.';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: widget.controller.isLoading
                                ? null
                                : _changeEmail,
                            child: const Text('Update Email'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: FlockColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: _passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_statusMessage != null &&
                              _statusSection == 'password') ...[
                            FlockMessageBanner(
                              message: _statusMessage!,
                              isError: _statusIsError,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: Icon(Icons.lock_reset_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Use at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock_reset_outlined),
                            ),
                            validator: (value) {
                              if (value != _newPasswordController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: widget.controller.isLoading
                                ? null
                                : _changePassword,
                            child: const Text('Change Password'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FlockColors.tan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FlockColors.tan),
                      ),
                      child: const Text(
                        'Account changes are hidden for Google-auth accounts.',
                        style: TextStyle(color: FlockColors.darkGreen),
                      ),
                    ),
                  ],
                  if (isPasswordUser) ...[
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      onPressed: widget.controller.isLoading
                          ? null
                          : _deleteAccount,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade800,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Account'),
                    ),
                    if (_statusMessage != null && _statusSection == 'delete') ...[
                      const SizedBox(height: 12),
                      FlockMessageBanner(
                        message: _statusMessage!,
                        isError: _statusIsError,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
