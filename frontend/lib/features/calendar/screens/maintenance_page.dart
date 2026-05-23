import 'package:flutter/material.dart';
import '../widgets/calendar.dart';
import '../widgets/upcoming.dart';
import 'package:flocksync/core/theme/flock_theme.dart';
import 'package:flocksync/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flocksync/features/settings/screens/settings_screen.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Builder(
              builder: (context) {
                final width = MediaQuery.of(context).size.width;

                final horizontalPadding =
                    width > 1200 ? 64.0 : 16.0;

                return ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            Text(
                              "FlockSync",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsScreen(
                                  user: FirebaseAuth.instance.currentUser!,
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

                    Text(
                      "Calendar",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGreen,
                      ),
                    ),

                    const SizedBox(height: 15),

                    MaintenanceCalendar(),

                    const SizedBox(height: 20),

                    UpcomingMaintenance(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}