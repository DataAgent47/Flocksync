import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/flock_theme.dart';
import '../../../core/widgets/flock_message_banner.dart';
import '../../../core/widgets/settings_tile.dart';
import '../controllers/settings_controller.dart';
import 'building_settings_screen.dart';
import 'profile_settings_screen.dart';
import 'security_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  final User user;

  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController _controller;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
  }

  Future<void> _signOut() async {
    final ok = await _controller.signOut();
    if (!mounted || ok) {
      return;
    }

    setState(() {
      _statusMessage = _controller.errorMessage ?? 'Sign out failed.';
      _statusIsError = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: FlockColors.cream,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: FlockColors.darkGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your account and privacy preferences.',
                  style: TextStyle(
                    color: FlockColors.textSecondary,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                StreamBuilder(
                  stream: _controller.profileStream(widget.user.uid),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    final fullName = profile == null
                        ? ''
                        : '${profile.firstName} ${profile.lastName}'.trim();
                    final photoUrl = (profile?.photoUrl ??
                        FirebaseAuth.instance.currentUser?.photoURL ??
                        '')
                      .trim();

                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: FlockColors.darkGreen,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: FlockColors.tan,
                            backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: FlockColors.darkGreen,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fullName.isEmpty ? 'Your Profile' : fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: FlockColors.darkGreen,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  FlockMessageBanner(
                    message: _statusMessage!,
                    isError: _statusIsError,
                  ),
                ],
                const SizedBox(height: 20),
                SettingsTile(
                  title: 'Profile',
                  subtitle: 'Edit name, contact email, and phone number',
                  leadingIcon: Icons.person_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileSettingsScreen(
                          uid: widget.user.uid,
                          controller: _controller,
                        ),
                      ),
                    );
                  },
                ),
                SettingsTile(
                  title: 'Building Settings',
                  subtitle:
                      'View or edit your building information.',
                  leadingIcon: Icons.apartment_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BuildingSettingsScreen(
                          uid: widget.user.uid,
                          controller: _controller,
                        ),
                      ),
                    );
                  },
                ),
                SettingsTile(
                  title: 'Security',
                  subtitle: 'Change login email, password, and account status',
                  leadingIcon: Icons.lock_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SecuritySettingsScreen(
                          uid: widget.user.uid,
                          user: widget.user,
                          controller: _controller,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _controller.isLoading ? null : _signOut,
                  icon: _controller.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
