import 'package:flutter/material.dart';
import '../widgets/calendar.dart';
import '../widgets/upcoming.dart';
import '../color.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: AppColors.darkGreen,
        unselectedItemColor: Colors.grey,
        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Dashboard",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Calendar",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            label: "Forums",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Settings",
          ),
        ],
      ),

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

                  const CircleAvatar()

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
              )

            ],
          ),
        ),
      ),
    );
  }
}