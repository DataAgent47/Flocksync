import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/booking_page.dart';
import '../../../core/theme/flock_theme.dart';

class MaintenanceCalendar extends StatefulWidget {
  const MaintenanceCalendar({super.key});

  @override
  State<MaintenanceCalendar> createState() => _MaintenanceCalendarState();
}

class _MaintenanceCalendarState extends State<MaintenanceCalendar> {

  DateTime today = DateTime.now();
  DateTime currentMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();

  String? selectedSlot;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final List<String> weekdaySlots = [
    "9 AM",
    "12 PM",
    "3 PM",
  ];

  bool isWeekend(DateTime day) {
    return day.weekday == DateTime.saturday ||
        day.weekday == DateTime.sunday;
  }

  bool isPastDay(DateTime day) {
    return day.isBefore(DateTime(today.year, today.month, today.day));
  }

  Future<List<String>> getBookedSlots(DateTime date) async {

    String dateKey = "${date.year}-${date.month}-${date.day}";

    QuerySnapshot snapshot = await firestore
        .collection('bookings')
        .where('date', isEqualTo: dateKey)
        .get();

    return snapshot.docs
        .map((doc) => doc['slot'].toString())
        .toList();
  }

  String monthName(int month) {
    const months = [
      "January","February","March","April",
      "May","June","July","August",
      "September","October","November","December"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {

    int daysInMonth =
        DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month);

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
          )
        ],
      ),

      child: Column(
        children: [

          const Text(
            "Schedule Maintenance",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    currentMonth = DateTime(
                      currentMonth.year,
                      currentMonth.month - 1,
                    );
                  });
                },
              ),

              Text(
                "${monthName(currentMonth.month)} ${currentMonth.year}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),

              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    currentMonth = DateTime(
                      currentMonth.year,
                      currentMonth.month + 1,
                    );
                  });
                },
              ),

            ],
          ),

          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth,

            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),

            itemBuilder: (context, index) {

              DateTime day = DateTime(
                  currentMonth.year,
                  currentMonth.month,
                  index + 1);

              bool isSelected =
                  selectedDate.year == day.year &&
                  selectedDate.month == day.month &&
                  selectedDate.day == day.day;

              bool disabled =
                  isWeekend(day) || isPastDay(day);

              return GestureDetector(
                onTap: disabled ? null : () {

                  setState(() {
                    selectedDate = day;
                    selectedSlot = null;
                  });

                },

                child: Container(
                  decoration: BoxDecoration(

                    color: isSelected
                        ? AppColors.darkGreen
                        : disabled
                        ? Colors.grey[300]
                        : Colors.transparent,

                    shape: BoxShape.circle,

                    border: !disabled && !isSelected
                        ? Border.all(color: AppColors.green2)
                        : null,
                  ),

                  alignment: Alignment.center,

                  child: Text(
                    "${day.day}",
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : disabled
                          ? Colors.grey
                          : AppColors.darkGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          FutureBuilder<List<String>>(
            future: getBookedSlots(selectedDate),

            builder: (context, snapshot) {

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              List<String> booked =
                  snapshot.data ?? [];

              List<String> available =
              weekdaySlots
                  .where((slot) =>
              !booked.contains(slot))
                  .toList();

              if (available.isEmpty) {
                return const Text("No available slots");
              }

              return Column(
                children: [

                  DropdownButtonFormField<String>(
                    hint: const Text("Select Time"),
                    initialValue: selectedSlot,

                    items: available.map((slot) {

                      return DropdownMenuItem(
                        value: slot,
                        child: Text(slot),
                      );

                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        selectedSlot = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      minimumSize:
                      const Size(double.infinity, 45),
                    ),

                    onPressed: selectedSlot == null
                        ? null
                        : () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BookingPage(
                                date: selectedDate,
                                slot: selectedSlot!,
                              ),
                        ),
                      );

                    },

                    child: const Text(
                      "Book Slot",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              );
            },
          )

        ],
      ),
    );
  }
}