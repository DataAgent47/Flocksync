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
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
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

                try {
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

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  print("ERROR SAVING EVENT: $e");
                }
              },
              child: const Text(
                "Save Event",
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            /// ✅ REQUEST MAINTENANCE (WITH NAVBAR)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green2,
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: () {
                Navigator.pop(context); // close modal

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const MainShell(initialIndex: 2), // ✅ KEY FIX
                  ),
                );
              },
              child: const Text(
                "Request Maintenance",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}