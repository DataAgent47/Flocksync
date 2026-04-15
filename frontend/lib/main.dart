import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/flock_theme.dart';
import 'firebase_options.dart';
import 'features/forum/screens/forum_feed_screen.dart';

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
      home: const MainShell(),
    );
  }
}

// ─── Main shell with bottom nav ────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 2; // start on Forums tab for testing

  // TODO: replace with real auth values once auth feature is merged
  static const _mockUserId = 'dev_user_001';
  static const _mockUserName = 'Dev User';
  static const _mockBuildingId = 'building_test_001';
  static const _mockIsManagement = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _PlaceholderScreen(label: 'Dashboard'),
          const _PlaceholderScreen(label: 'Calendar'),
          _ForumsLandingScreen(
            userId: _mockUserId,
            userName: _mockUserName,
            buildingId: _mockBuildingId,
            isManagement: _mockIsManagement,
          ),
          const _PlaceholderScreen(label: 'Settings'),
        ],
      ),
      bottomNavigationBar: _FlockBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
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
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share information and connect with your neighbors!',
                style: TextStyle(
                    fontSize: 16,
                    color: FlockColors.textSecondary,
                    height: 1.4),
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
              const _ForumTile(
                label: 'From your zip code',
                onTap: null,
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
                    color: FlockColors.darkGreen),
              ),
              const Icon(Icons.arrow_forward,
                  color: FlockColors.darkGreen, size: 20),
            ],
          ),
        ),
      ),
    );
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
            const Icon(Icons.construction_outlined,
                size: 48, color: FlockColors.tan),
            const SizedBox(height: 16),
            Text(label,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: FlockColors.darkGreen)),
            const SizedBox(height: 8),
            const Text('Coming soon',
                style: TextStyle(
                    color: FlockColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}