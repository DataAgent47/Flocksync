// import 'package:flocksync/models/forum_post.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/flock_theme.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/forum/screens/forum_feed_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/services/onboarding_firestore_service.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/calendar/screens/personal_calendar_page.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FlockSyncApp());
}

class FlockSyncApp extends StatelessWidget {
  const FlockSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlockSync',
      debugShowCheckedModeBanner: false,
      theme: flockTheme(),
      home: const _AuthGate(),
    );
  }
}

// Auth gate to make sure user is logged in
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        final isEmailPasswordUser = user.providerData.any(
          (info) => info.providerId == 'password',
        );
        if (isEmailPasswordUser && !user.emailVerified) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Force onboarding completion
        return StreamBuilder<bool>(
          stream: OnboardingFirestoreService().isOnboardingCompleted(user.uid),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final completed = onboardingSnapshot.data ?? false;
            if (!completed) {
              return OnboardingScreen(user: user);
            }
            return MainShell(user: user);
          },
        );
      },
    );
  }
}

// ─── Main shell with bottom nav ────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.user});

  final User user;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 2; // start on Forums tab for testing
  String? _firstName;
  String? _buildingId;
  bool _isManagement = false;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots()
        .listen((doc) {
          if (!mounted) return;
          final data = doc.data();
          if (data == null) return;
          setState(() {
            final name = data['first_name'] as String?;
            if (name != null && name.trim().isNotEmpty) {
              _firstName = name.trim();
            }

            // get Building ID from firestore
            _buildingId = data['property_id'] as String?;

            _isManagement = (data['role'] as String?) == 'manager';
          });
        });
  }

  // Get real name from firestore
  String get _userId => widget.user.uid;
  String get _userName {
    if (_firstName != null) return _firstName!;
    final displayName = widget.user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return 'Neighbor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardScreen(
            userId: _userId,
            userName: _userName,
            buildingId: _buildingId ?? '',
            isManagement: _isManagement,
            user: widget.user,
          ),
          const PersonalCalendarPage(),
          _ForumsLandingScreen(
            userId: _userId,
            userName: _userName,
            buildingId: _buildingId ?? '',
            isManagement: _isManagement,
          ),
          _SettingsScreen(user: widget.user),
        ],
      ),
      bottomNavigationBar: _FlockBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Dashboard — matches your mockup ──────────────────────────────────────
// You can run 'flutter run -d web-server' to debug.
class _DashboardScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String buildingId;
  final bool isManagement;
  final User user;

  const _DashboardScreen({
    required this.userId,
    required this.userName,
    required this.buildingId,
    required this.isManagement,
    required this.user,
  });

  /// Contains the containers and elements of the Dashboard:
  ///  - Building Announcements
  ///  - Upcoming Events
  ///  - Calendar
  ///  - Forum Activity
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlockColors.background,
      body: ListView(
        // Automatically adds 16px gap between all 'children' or elements.
        padding: const EdgeInsets.all(16),
        // Contains 'children' or elements for the Dashboard.
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Primary text that writes 'Welcome!'
              const Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: FlockColors.textPrimary
                )
              ),

              GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      user: user,
                      showBackButton: true,
                    ),
                  )
                );
              },
              child: profileImage(),
              )
            ]
          ),

          const SizedBox(height: 20),

          // Secondary text that introduces users to FlockSync.
          const Text(
            'Navigate FlockSync and see building announcements, upcoming events, and more!',
            style: TextStyle(
              fontSize: 16,
              color: FlockColors.textSecondary,
            )
          ),

          const SizedBox(height: 20),

          // Announces new dashboard content
          const AnnouncementCard(
            title: 'Important Update',
            message: 'Check out the new features!',
            icon: Icons.campaign,
          ),

          const SizedBox(height: 20),

          // Calendar
          titleSection('Calendar'),
          const SizedBox(height: 10),
          cardContainer(
            height: 520,
            child: PersonalCalendarPage(),
          ),

          const SizedBox(height: 20),

          // Forum
          titleSection('Forum Activity'),
          const SizedBox(height: 10),
          cardContainer(
            height: 520,
            child: ForumFeedScreen(
              buildingId: buildingId,
              currentUserId: userId,
              currentUserName: userName,
              isManagement: isManagement,
            ),
          ),
        ],
      ),
    );
  }

  // Reusable card container
  Widget cardContainer({required double height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FlockColors.cream,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: FlockColors.darkGreen
          )
        ],
      ),
      child: child,
    );
  }

  // Title Section
  Widget titleSection(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class AnnouncementCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AnnouncementCard({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold
          )
        ),
        subtitle: Text(message)
      ),
    );
  }
}

@override
Widget profileImage() {
  return _HoverProfileImage();
}

class _HoverProfileImage extends StatefulWidget {
  @override
  State<_HoverProfileImage> createState() => _HoverProfileImageState();
}

class _HoverProfileImageState extends State<_HoverProfileImage> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),

      child: Transform.scale(
        scale: isHovered ? 1.08 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: FlockColors.darkGreen,
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: FlockColors.tan,
            backgroundImage:
                (FirebaseAuth.instance.currentUser?.photoURL?.isNotEmpty ?? false)
                    ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                    : null,
            child: (FirebaseAuth.instance.currentUser?.photoURL?.isEmpty ?? true)
                ? const Icon(
                    Icons.person,
                    size: 30,
                    color: FlockColors.darkGreen,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

// ─── Forums landing — matches your mockup ──────────────────────────────────────

class _ForumsLandingScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String buildingId;
  final bool isManagement;

  const _ForumsLandingScreen({
    required this.userId,
    required this.userName,
    required this.buildingId,
    required this.isManagement,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlockColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forums',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: FlockColors.darkGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share information and connect with your neighbors!',
                style: TextStyle(
                  fontSize: 16,
                  color: FlockColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),

              // Building forum — active
              _ForumTile(
                label: 'From your building',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ForumFeedScreen(
                      buildingId: buildingId,
                      currentUserId: userId,
                      currentUserName: userName,
                      isManagement: isManagement,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Zip code forum — coming soon
              const _ForumTile(label: 'From your zip code', onTap: null),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForumTile extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ForumTile({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: FlockColors.tan,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: FlockColors.darkGreen,
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                color: FlockColors.darkGreen,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Settings screen ───────────────────────────────────────────────────────────────

class _SettingsScreen extends StatelessWidget {
  final User user;

  const _SettingsScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(user: user);
  }
}

// ─── Bottom nav ────────────────────────────────────────────────────────────────

class _FlockBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _FlockBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: FlockColors.cream,
      selectedItemColor: FlockColors.darkGreen,
      unselectedItemColor: FlockColors.textMuted,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum_outlined),
          activeIcon: Icon(Icons.forum),
          label: 'Forums',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

// ─── Placeholder for unbuilt tabs ──────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlockColors.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.construction_outlined,
              size: 48,
              color: FlockColors.tan,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: FlockColors.darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming soon',
              style: TextStyle(color: FlockColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}