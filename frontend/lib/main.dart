// import 'package:flocksync/models/forum_post.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/flock_theme.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/forum/screens/forum_feed_screen.dart';
import 'models/forum_post.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/services/onboarding_firestore_service.dart';
import 'features/settings/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // ── Local emulator (dev only) ──────────────────────────────────────────
  const bool kUseEmulator = bool.fromEnvironment('USE_EMULATOR');
  if (kUseEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  // ───────────────────────────────────────────────────────────────────────
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
  int _currentIndex = 0; // default to Dashboard
  String? _firstName;
  String? _buildingId;
  String _zipCode = '';
  bool _isManagement = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots()
        .listen((doc) async {
          if (!mounted) return;
          final data = doc.data();
          if (data == null) return;
          final onboardingState =
              data['onboarding_state'] as Map<String, dynamic>?;
          final nextBuildingId = onboardingState?['property_id'] as String?;
          final role = (data['role'] as String?) ?? 'resident';
          final verified = await _lookupVerification(
            role: role,
            buildingId: nextBuildingId,
          );
          final postalCode = await _lookupPostalCode(nextBuildingId);
          setState(() {
            final name = data['first_name'] as String?;
            if (name != null && name.trim().isNotEmpty) {
              _firstName = name.trim();
            }

            // get Building ID from firestore
            _buildingId = nextBuildingId;

            _isManagement = role == 'manager';
            _isVerified = verified;
            _zipCode = postalCode;
          });
        });
  }

  Future<bool> _lookupVerification({
    required String role,
    required String? buildingId,
  }) async {
    if (buildingId == null || buildingId.trim().isEmpty) return false;
    final collection = role == 'manager' ? 'managers' : 'residents';
    final membershipId = '${buildingId}_${widget.user.uid}';
    final doc = await FirebaseFirestore.instance
        .collection(collection)
        .doc(membershipId)
        .get();
    return (doc.data()?['is_verified'] as bool?) ?? false;
  }

  Future<String> _lookupPostalCode(String? buildingId) async {
    if (buildingId == null || buildingId.trim().isEmpty) return '';
    final doc = await FirebaseFirestore.instance
        .collection('properties')
        .doc(buildingId)
        .get();
    return (doc.data()?['postal_code'] as String? ?? '').trim();
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
            zipCode: _zipCode,
            isManagement: _isManagement,
            isVerified: _isVerified,
            user: widget.user,
          ),
          const _PlaceholderScreen(label: 'Calendar'),
          _ForumsLandingScreen(
            userId: _userId,
            userName: _userName,
            buildingId: _buildingId ?? '',
            zipCode: _zipCode,
            isManagement: _isManagement,
            isVerified: _isVerified,
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
  final String zipCode;
  final bool isManagement;
  final bool isVerified;
  final User user;

  const _DashboardScreen({
    required this.userId,
    required this.userName,
    required this.buildingId,
    required this.zipCode,
    required this.isManagement,
    required this.isVerified,
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
      body: SafeArea(
        child: SingleChildScrollView(
          // Padding for the top left, top, and right.
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          // Elements are contained within a vertical structure.
          child: Column(
            // Aligns 'children' or elements to the beginning of the cross axis, or left.
            crossAxisAlignment: CrossAxisAlignment.start,
            // Automatically adds 16px gap between all 'children' or elements.
            spacing: 16,
            // Contains 'children' or elements for the Dashboard.
            children: [
              // Primary text that writes 'Welcome!'
              const Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: FlockColors.textPrimary,
                ),
              ),

              // Secondary text that introduces users to FlockSync.
              const Text(
                'Navigate FlockSync and see building announcements, upcoming events, and more!',
                style: TextStyle(
                  fontSize: 16,
                  color: FlockColors.textSecondary,
                ),
              ),

              // Announces new dashboard content
              const AnnouncementCard(
                title: 'Important Update',
                message: 'Check out the new features!',
                icon: Icons.campaign,
              ),

              // Primary text above building announcements.
              const Text(
                'Building Forum',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: FlockColors.textPrimary,
                ),
              ),

              // Building Announcements.
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: FlockColors.darkGreen),
                ),

                // Building Announcements.
                child: isVerified
                    ? ForumFeedScreen(
                        buildingId: buildingId,
                        currentUserId: userId,
                        currentUserName: userName,
                        isManagement: isManagement,
                      )
                    : const _ForumAccessMessage(
                        message:
                            'Building forums are available after verification.',
                      ),
              ),

              // Elements are contained within a horizontal structure.
              Row(
                // Aligns 'children' or elements to the beginning of the cross axis, or top.
                crossAxisAlignment: CrossAxisAlignment.start,
                // Contains 'children' or elements for the Dashboard.
                children: [
                  // --- LEFT COLUMN ---
                  Expanded(
                    child: Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Upcoming Events',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: FlockColors.textPrimary,
                          ),
                        ),

                        // Upcoming Events
                        Container(
                          height: 666,
                          decoration: BoxDecoration(
                            border: Border.all(color: FlockColors.textPrimary),
                          ),
                          // Upcoming Events
                          child: _PlaceholderScreen(label: 'Upcoming Events'),
                        ),
                      ],
                    ),
                  ),

                  // Space between the left and right sides.
                  const SizedBox(width: 24),

                  // --- RIGHT COLUMN ---
                  Expanded(
                    child: Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calendar',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: FlockColors.textPrimary,
                          ),
                        ),

                        // Calendar Activity
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(color: FlockColors.textPrimary),
                          ),
                          // Calendar
                          child: _PlaceholderScreen(label: 'Calendar'),
                        ),

                        const Text(
                          'Building Announcements',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: FlockColors.textPrimary,
                          ),
                        ),

                        // Forum Feed Activity
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(color: FlockColors.textPrimary),
                          ),

                          // Building Announcements
                          child: _PlaceholderScreen(
                            label: 'Building Announcements',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(message),
      ),
    );
  }
}

// ─── Forums landing — matches your mockup ──────────────────────────────────────

class _ForumsLandingScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String buildingId;
  final String zipCode;
  final bool isManagement;
  final bool isVerified;

  const _ForumsLandingScreen({
    required this.userId,
    required this.userName,
    required this.buildingId,
    required this.zipCode,
    required this.isManagement,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final hasBuildingRequest = buildingId.trim().isNotEmpty;
    final hasZipContext = zipCode.trim().isNotEmpty;
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
                onTap: isVerified
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForumFeedScreen(
                            buildingId: buildingId,
                            currentUserId: userId,
                            currentUserName: userName,
                            isManagement: isManagement,
                          ),
                        ),
                      )
                    : () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Only verified residents and staff can use building forums.',
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              _ForumTile(
                label: 'From your zip code',
                onTap: hasBuildingRequest && hasZipContext
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForumFeedScreen(
                            buildingId: buildingId,
                            forumType: ForumType.neighborhood,
                            forumKey: zipCode,
                            currentUserId: userId,
                            currentUserName: userName,
                            isManagement: isManagement,
                          ),
                        ),
                      )
                    : null,
              ),
              if (!hasBuildingRequest || !hasZipContext)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Zip code forum unlocks once you request to join a building.',
                    style: TextStyle(
                      color: FlockColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
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

class _ForumAccessMessage extends StatelessWidget {
  final String message;
  const _ForumAccessMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: FlockColors.textSecondary,
            fontSize: 14,
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
