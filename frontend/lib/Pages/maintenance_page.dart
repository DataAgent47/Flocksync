import 'package:flutter/material.dart';
import 'booking_page.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});


  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}


class _MaintenancePageState extends State<MaintenancePage> {
  int selectedDay = 18;
  String? selectedSlot;


  final Color primaryGreen = const Color(0xFF2E7D67);
  final Color backgroundColor = const Color(0xFFF5F1EC);
  final Color primaryText = const Color(0xFF1A2A36);


  final Map<int, List<String>> availableSlots = {
    18: ["9 AM", "12 PM", "3 PM"],
    19: ["10 AM", "1 PM"],
    20: ["9 AM", "11 AM", "2 PM"],
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,


      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: ""),
        ],
      ),


      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [


              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("FlockSync",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen)),
                  const CircleAvatar()
                ],
              ),


              const SizedBox(height: 10),


              // Tab placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _tab("Home", true),
                  _tab("Dashboard", false),
                  _tab("Forums", false),
                ],
              ),


              const SizedBox(height: 20),


              // Title
              Center(
                child: Text(
                  "Maintenance & Announcements",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
              ),


              const SizedBox(height: 15),


              // Calendar card placeholder
              _calendarCard(),


              const SizedBox(height: 20),


              Expanded(child: _announcementCard())
            ],
          ),
        ),
      ),
    );
  }


  // Tabs
  Widget _tab(String text, bool active) {
    return Column(
      children: [
        Text(text,
            style: TextStyle(
                color: active ? primaryGreen : Colors.grey,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        if (active)
          Container(
            height: 3,
            width: 40,
            color: primaryGreen,
          )
      ],
    );
  }


  // Calendar
  Widget _calendarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          // Title
          Center(
            child: Text(
              "Schedule Maintenance",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
          ),


          const SizedBox(height: 10),


          Center(
            child: Text("March 2026",
                style: TextStyle(color: primaryText)),
          ),


          const SizedBox(height: 10),


          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 30,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              int day = index + 1;
              bool isSelected = day == selectedDay;
              bool isAvailable = availableSlots.containsKey(day);


              return GestureDetector(
                onTap: isAvailable
                    ? () {
                        setState(() {
                          selectedDay = day;
                          selectedSlot = null;
                        });
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryGreen
                        : isAvailable
                            ? Colors.transparent
                            : Colors.grey[300],
                    shape: BoxShape.circle,
                    border: isAvailable && !isSelected
                        ? Border.all(color: primaryGreen)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "$day",
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isAvailable
                              ? primaryText
                              : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),


          const SizedBox(height: 10),


          if (availableSlots[selectedDay] != null)
            DropdownButtonFormField<String>(
              initialValue: selectedSlot,
              hint: const Text("Select Time"),
              items: availableSlots[selectedDay]!
                  .map((slot) => DropdownMenuItem(
                        value: slot,
                        child: Text(slot),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedSlot = value;
                });
              },
            ),


          const SizedBox(height: 12),


          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: selectedSlot == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingPage(
                          day: selectedDay,
                          slot: selectedSlot!,
                        ),
                      ),
                    );
                  },
            child: const Text("Book Slot",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }


  // Announcement card
  Widget _announcementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Building Announcements",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryText)),


          const SizedBox(height: 10),


          _announcement(
              Icons.build,
              "Elevator Maintenance",
              "Scheduled for April 18"),


          _announcement(
              Icons.water_drop,
              "Water Shutdown",
              "Planned on April 20"),
        ],
      ),
    );
  }


  Widget _announcement(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: Icon(icon, color: primaryGreen),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: primaryText)),
      subtitle: Text(subtitle),
    );
  }


  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
