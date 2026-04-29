import 'package:flutter/material.dart';
import 'package:flocksync/core/theme/flock_theme.dart';
import '../screens/maintenance_page.dart';

class PersonalCalendarPage extends StatefulWidget {
  const PersonalCalendarPage({super.key});

  @override
  State<PersonalCalendarPage> createState() => _PersonalCalendarPageState();
}

class _PersonalCalendarPageState extends State<PersonalCalendarPage> {

  DateTime currentMonth = DateTime.now();
  Map<String, List<Map<String, String>>> events = {};

  String monthName(int month) {
    const months = [
      "January","February","March","April",
      "May","June","July","August",
      "September","October","November","December"
    ];
    return months[month - 1];
  }

  String getDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  // nav handler
  void _handleNavTap(int index) {
    switch (index) {
      case 0:
        // Navigator.pushReplacement(context,
        //   MaterialPageRoute(builder: (_) => DashboardPage()));
        break;

      case 1:
        // already on calendar
        break;

      case 2:
        // Navigator.pushReplacement(context,
        //   MaterialPageRoute(builder: (_) => ForumsPage()));
        break;

      case 3:
        // Navigator.pushReplacement(context,
        //   MaterialPageRoute(builder: (_) => SettingsPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {

    int daysInMonth =
        DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month);

    int firstWeekday =
        DateTime(currentMonth.year, currentMonth.month, 1).weekday;

    int totalCells = daysInMonth + (firstWeekday % 7);

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
                "My Calendar",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),

              const SizedBox(height: 15),

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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Text("Sun"),
                  Text("Mon"),
                  Text("Tue"),
                  Text("Wed"),
                  Text("Thu"),
                  Text("Fri"),
                  Text("Sat"),
                ],
              ),

              const SizedBox(height: 8),

              Expanded(
                child: GridView.builder(
                  itemCount: totalCells,

                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 95,
                  ),

                  itemBuilder: (context, index) {

                    if (index < (firstWeekday % 7)) {
                      return const SizedBox();
                    }

                    int dayNumber = index - (firstWeekday % 7) + 1;

                    DateTime day = DateTime(
                      currentMonth.year,
                      currentMonth.month,
                      dayNumber,
                    );

                    String key = getDateKey(day);
                    List dayEvents = events[key] ?? [];

                    return GestureDetector(
                      onTap: () {
                        _openDayModal(day);
                      },

                      child: Container(
                        padding: const EdgeInsets.all(6),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              "$dayNumber",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 4),

                            ...dayEvents.take(2).map((event) {
                              return Text(
                                event["title"] ?? "",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                ),
                                overflow: TextOverflow.ellipsis,
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDayModal(DateTime day) {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController timeController = TextEditingController();

    String key = getDateKey(day);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      builder: (context) {

        return Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(
                "${day.month}/${day.day}/${day.year}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text("Add Event"),

              const SizedBox(height: 10),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: "Time"),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  if (titleController.text.isEmpty) return;

                  setState(() {
                    events.putIfAbsent(key, () => []);
                    events[key]!.add({
                      "title": titleController.text,
                      "description": descriptionController.text,
                      "time": timeController.text,
                    });
                  });

                  Navigator.pop(context);
                },
                child: const Text(
                  "Save Event",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green2,
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MaintenancePage(),
                    ),
                  );
                },
                child: const Text(
                  "Request Maintenance",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}