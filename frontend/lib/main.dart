// import 'package:flocksync/models/forum_post.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/flock_theme.dart';
import 'core/widgets/settings_tile.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/forum/screens/announcements_screen.dart';
import 'features/forum/screens/forum_feed_screen.dart';
import 'models/forum_post.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/services/onboarding_firestore_service.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/calendar/screens/personal_calendar_page.dart';
import 'features/users/screens/users_screen.dart';

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
            // if (onboardingSnapshot.hasError) {
            //   // Return to login if firestore fails
            //   return const LoginScreen();
            // }
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
  int _currentIndex = 0;
  String? _firstName;
  String? _buildingId;
  String _zipCode = '';
  bool _isManagement = false;
  bool _isVerified = false;
  bool _isRejected = false;
  // Fix permissions issues during signout
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots()
        .listen((doc) async {
          if (!mounted) return;
          final data = doc.data();
          if (data == null) return;
          final onboardingState =
              data['onboarding_state'] as Map<String, dynamic>?;
          final fromOnboarding =
              (onboardingState?['property_id'] as String?)?.trim() ?? '';
          final fromRoot = (data['property_id'] as String?)?.trim() ?? '';
          final resolvedBuildingId =
              fromRoot.isNotEmpty ? fromRoot : fromOnboarding;
          final role = (data['role'] as String?) ?? 'resident';

          final verified = await _lookupVerification(
            role: role,
            buildingId:
                resolvedBuildingId.isEmpty ? null : resolvedBuildingId,
          );
          final rejected = await _lookupRejectionStatus(
            role: role,
            buildingId:
                resolvedBuildingId.isEmpty ? null : resolvedBuildingId,
          );
          final postalCode = await _lookupPostalCode(
            resolvedBuildingId.isEmpty ? null : resolvedBuildingId,
          );
          setState(() {
            final name = data['first_name'] as String?;
            if (name != null && name.trim().isNotEmpty) {
              _firstName = name.trim();
            }

            _buildingId =
                resolvedBuildingId.isEmpty ? null : resolvedBuildingId;
            _isManagement = role == 'manager';
            _isVerified = verified;
            _isRejected = rejected;
            _zipCode = postalCode;
          });
        }, onError: (error) {
          // Silent Clear permissions errors
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

  Future<bool> _lookupRejectionStatus({
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
    return (doc.data()?['verified_rejected'] as bool?) ?? false;
  }

  Future<String> _lookupPostalCode(String? buildingId) async {
    if (buildingId == null || buildingId.trim().isEmpty) return '';
    final doc = await FirebaseFirestore.instance
        .collection('properties')
        .doc(buildingId)
        .get();
    return (doc.data()?['postal_code'] as String? ?? '').trim();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
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
            isRejected: _isRejected,
          ),
          _UsersScreen(
            userId: _userId,
            userName: _userName,
            buildingId: _buildingId ?? '',
            isManagement: _isManagement,
          ),
          const PersonalCalendarPage(),
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
// You can run the server and test it on another device using:
// flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8081
// Then join using the corresponding link:
// http:<IPv4 Address>:8081
class _CategoryOption {
  final String title;
  final PostCategory category;
  const _CategoryOption(this.title, this.category);
}

final ValueNotifier<PostCategory> _selectedCategory =
    ValueNotifier(PostCategory.announcement);

class _DashboardScreen extends StatelessWidget {
  final List<_CategoryOption> _options = const [
    _CategoryOption("Announcements", PostCategory.announcement),
    _CategoryOption("General", PostCategory.general),
    _CategoryOption("Maintenance", PostCategory.maintenance),
    _CategoryOption("Marketplace", PostCategory.marketplace),
    _CategoryOption("Question", PostCategory.question),
  ];
  
  final String userId;
  final String userName;
  final String buildingId;
  final String zipCode;
  final bool isManagement;
  final bool isVerified;
  final User user;
  final bool isRejected;

  const _DashboardScreen({
    required this.userId,
    required this.userName,
    required this.buildingId,
    required this.zipCode,
    required this.isManagement,
    required this.isVerified,
    required this.user,
    required this.isRejected,
  });

  PostCategory _next(PostCategory current) {
    final i = _options.indexWhere((o) => o.category == current);
    return _options[(i + 1) % _options.length].category;
  }

  PostCategory _prev(PostCategory current) {
    final i = _options.indexWhere((o) => o.category == current);
    return _options[(i - 1 + _options.length) % _options.length].category;
  }

  String _label(PostCategory c) {
    return _options.firstWhere((o) => o.category == c).title;
  }
  
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
                  color: FlockColors.textPrimary,
                ),
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
                    ),
                  );
                },
                child: profileImage(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Secondary text that introduces users to FlockSync.
          const Text(
            'Navigate FlockSync and see building announcements, upcoming events, and more!',
            style: TextStyle(
              fontSize: 16,
              color: FlockColors.textSecondary,
            ),
          ),

          const SizedBox(height: 10),

          // Account rejection banner
          if (isRejected)
            const AnnouncementCard(
              title: 'Account Status',
              message: 'Your account has been rejected. Please contact management for more information or edit your details to reapply.',
              icon: Icons.warning_outlined,
            ),

          // Announces new dashboard content
          const AnnouncementCard(
            title: 'Important Update',
            message: 'Check out the new features!',
            icon: Icons.campaign,
          ),

          const SizedBox(height: 20),
          
          ValueListenableBuilder<PostCategory>(
            valueListenable: _selectedCategory,
            builder: (context, selected, _) {
              final label = _label(selected);

              return Container(
                decoration: BoxDecoration(
                  color: FlockColors.cream,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),

                    _ArrowButton(
                      icon: Icons.chevron_left,
                      onTap: () => _selectedCategory.value =
                          _prev(_selectedCategory.value),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnnouncementsScreen(
                                buildingId: buildingId,
                                forumType: ForumType.building,
                                forumKey: buildingId,
                                currentUserId: userId,
                                currentUserName: userName,
                                category: selected,
                                title: label,
                                currentUserAvatarUrl: '',
                                isManagement: isManagement,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    _ArrowButton(
                      icon: Icons.chevron_right,
                      onTap: () => _selectedCategory.value = _next(_selectedCategory.value),
                    ),

                    const SizedBox(width: 16),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),

          // Forum
          titleSection('Active Appointments'),
          const SizedBox(height: 10),
          const ActiveAppointmentsWidget()
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
            color: Colors.black
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

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: FlockColors.buttonBackground,
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class ActiveAppointmentsWidget extends StatelessWidget {
  const ActiveAppointmentsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final stream = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('events')
      .orderBy('dateKey')
      .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Text("No active appointments right now.");
        }

        return ListView(
          shrinkWrap: true,
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return ListTile(
              title: Text(data["title"] ?? ""),
              subtitle: Text("${data["dateKey"]} • ${data["time"]}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await doc.reference.delete();
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

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
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
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
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Same Card + ListTile pattern as Settings (Profile, Building, Security).
                    SettingsTile(
                      title: 'From your building',
                      subtitle:
                          'Posts from residents and staff in your building.',
                      leadingIcon: Icons.apartment_outlined,
                      onTap: isVerified
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ForumFeedScreen(
                                    buildingId: buildingId,
                                    currentUserId: userId,
                                    currentUserName: userName,
                                    isManagement: isManagement,
                                    isVerified: isVerified,
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
                    AnimatedOpacity(
                      opacity: hasBuildingRequest && hasZipContext
                          ? 1
                          : 0.45,
                      duration: const Duration(milliseconds: 150),
                      child: SettingsTile(
                        title: 'From your zip code',
                        subtitle:
                            'Posts from neighbors in the same zip code area.',
                        leadingIcon: Icons.map_outlined,
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
                                      isVerified: isVerified,
                                    ),
                                  ),
                                )
                            : null,
                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Users screen ────────────────────────────────────────────────────────────────

class _UsersScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String buildingId;
  final bool isManagement;

  const _UsersScreen({
    required this.userId,
    required this.userName,
    required this.buildingId,
    required this.isManagement,
  });

  @override
  Widget build(BuildContext context) {
    return UsersScreen(
      userId: userId,
      userName: userName,
      buildingId: buildingId,
      isManagement: isManagement,
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
          icon: Icon(Icons.group_outlined),
          activeIcon: Icon(Icons.group),
          label: 'Users',
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

// ignore: unused_element
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