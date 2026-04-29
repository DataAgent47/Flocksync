import 'package:flutter/material.dart';
import '../widgets/calendar.dart';
import '../widgets/upcoming.dart';
import 'package:flocksync/core/theme/flock_theme.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "FlockSync",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const CircleAvatar(),
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

              const MaintenanceCalendar(),

              const SizedBox(height: 20),

              const Expanded(
                child: UpcomingMaintenance(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}