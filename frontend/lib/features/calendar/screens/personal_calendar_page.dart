import 'package:flutter/material.dart';
import 'package:flocksync/core/theme/flock_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/add_event_modal.dart';
import 'package:flocksync/main.dart';
import 'package:flocksync/features/settings/screens/settings_screen.dart';

class PersonalCalendarPage extends StatefulWidget {
  const PersonalCalendarPage({super.key});

  @override
  State<PersonalCalendarPage> createState() => _PersonalCalendarPageState();
}

class _PersonalCalendarPageState extends State<PersonalCalendarPage> {
  DateTime currentMonth = DateTime.now();

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> get eventsStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events')
        .orderBy('dateKey')
        .snapshots();
  }

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
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aligned page header 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Calendar",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGreen,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "View and manage your upcoming events.",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.4,
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
              
              const SizedBox(height: 24),

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

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text("Sun"), Text("Mon"), Text("Tue"),
                  Text("Wed"), Text("Thu"), Text("Fri"), Text("Sat"),
                ],
              ),

              const SizedBox(height: 8),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: eventsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    // rebuild your map from live data
                    final Map<String, List<Map<String, dynamic>>> events = {};

                    for (final doc in docs) {
                      final data = doc.data();
                      final date = data['dateKey'] as String;

                      events.putIfAbsent(date, () => []);
                      events[date]!.add({
                        "id": doc.id,
                        "title": data['title'],
                        "description": data['description'],
                        "time": data['time'],
                      });
                    }

                    return GridView.builder(
                      itemCount: totalCells,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                          onTap: () => _openDayModal(day, events),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.darkGreen,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
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

  void _openDayModal(DateTime day, Map<String, List<Map<String, dynamic>>> events) {
    String key = getDateKey(day);
    List dayEvents = events[key] ?? [];

    if (dayEvents.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "${day.month}/${day.day}/${day.year}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ...dayEvents.map((event) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          _buildRich("Title: ", event["title"]),
                          _buildRich("Description: ", event["description"]),
                          _buildRich("Time: ", event["time"]),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _editEvent(event);
                                  },
                                  child: const Text("Edit"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .collection('events')
                                        .doc(event["id"])
                                        .delete();

                                    if (!mounted || !context.mounted) return;
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Delete"),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddEventModal(
          dateKey: key,
          onSave: () async {},
          onRequestMaintenance: () {
            Navigator.pop(context);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MainShell(
                  user: FirebaseAuth.instance.currentUser!,
                  initialIndex: 2,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRich(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 18),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: value,
          ),
        ],
      ),
    );
  }

  void _editEvent(Map event) {
    TextEditingController titleController =
        TextEditingController(text: event["title"]);
    TextEditingController descriptionController =
        TextEditingController(text: event["description"]);
    TextEditingController timeController =
        TextEditingController(text: event["time"]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [

                const Text(
                  "Edit Event",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

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
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('events')
                        .doc(event["id"])
                        .update({
                      "title": titleController.text,
                      "description": descriptionController.text,
                      "time": timeController.text,
                    });

                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text("Save Changes"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
