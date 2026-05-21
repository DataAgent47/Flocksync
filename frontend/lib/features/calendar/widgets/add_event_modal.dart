import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/flock_theme.dart';
import '../screens/maintenance_page.dart';

class AddEventModal extends StatefulWidget {
  final String dateKey;
  final Future<void> Function() onSave;
  final VoidCallback onRequestMaintenance;

  const AddEventModal({
    super.key,
    required this.dateKey,
    required this.onSave,
    required this.onRequestMaintenance,
  });

  @override
  State<AddEventModal> createState() => _AddEventModalState();
}

class _AddEventModalState extends State<AddEventModal> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController timeController;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    timeController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.dateKey,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () async {
                    if (titleController.text.isEmpty || uid == null) return;

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('events')
                        .add({
                      "dateKey": widget.dateKey,
                      "title": titleController.text,
                      "description": descriptionController.text,
                      "time": timeController.text,
                      "userId": uid,
                    });

                    await widget.onSave();

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Save Event", style: TextStyle(color: Colors.white)),
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
                        builder: (_) => const MaintenancePage(),
                      ),
                    );
                  },
                  child: const Text("Request Maintenance",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}