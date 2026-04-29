import 'package:flutter/material.dart';
import '../../../core/theme/flock_theme.dart';

class UpcomingMaintenance extends StatelessWidget {
  const UpcomingMaintenance({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0,4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(
            "Upcoming Maintenance",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),

          const SizedBox(height: 10),

          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Icon(
                Icons.build,
                color: AppColors.darkGreen,
              ),
            ),
            title: const Text("Elevator Maintenance"),
            subtitle: const Text("Scheduled for April 18"),
          ),

          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Icon(
                Icons.water_drop,
                color: AppColors.darkGreen,
              ),
            ),
            title: const Text("Water Shutdown"),
            subtitle: const Text("Planned on April 20"),
          ),

        ],
      ),
    );
  }
}