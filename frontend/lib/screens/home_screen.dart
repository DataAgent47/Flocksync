import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final photoURL = user.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flocksync'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              // Auth state stream handles routing back to login
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.darkGreen,
                backgroundImage: photoURL != null
                    ? NetworkImage(photoURL)
                    : null,
                child: photoURL == null
                    ? Text(
                        (user.email?.isNotEmpty == true)
                            ? user.email![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          color: AppColors.background,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                'You\'re signed in!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                user.email ?? 'No email',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                  ?.copyWith(color: AppColors.green2),
              ),
              const SizedBox(height: 4),
              Text(
                'UID: ${user.uid}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                  ?.copyWith(color: AppColors.middleground),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.rocket_launch),
                label: const Text('Start Onboarding'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  foregroundColor: AppColors.background,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async => await authService.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
