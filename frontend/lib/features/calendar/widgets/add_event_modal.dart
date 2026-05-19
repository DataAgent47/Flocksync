import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/flock_theme.dart';
import '../../../main.dart'; 

class AddEventModal extends StatelessWidget {
  final String dateKey;
  final Future<void> Function() onSave;

  const AddEventModal({
    super.key,
    required this.dateKey,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController timeController = TextEditingController();

    final user = FirebaseAuth.instance.currentUser;
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
                  dateKey,
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
                      "date": dateKey,
                      "title": titleController.text,
                      "description": descriptionController.text,
                      "time": timeController.text,
                      "userId": uid,
                    });

                    await onSave();

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
                        builder: (context) =>
                            MainShell(user: user!, initialIndex: 2),
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