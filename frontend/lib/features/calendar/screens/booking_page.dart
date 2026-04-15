import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/flock_theme.dart';

class BookingPage extends StatefulWidget {

  final DateTime date;
  final String slot;

  const BookingPage({
    super.key,
    required this.date,
    required this.slot,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {

  String? selectedCategory;
  String? selectedUrgency;
  String? entryPermission;

  final TextEditingController descriptionController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        title: const Text("Book Maintenance"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "${widget.date.month}/${widget.date.day}/${widget.date.year} • ${widget.slot}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle("Category"),

            DropdownButtonFormField<String>(
              items: [
                "Plumbing",
                "Electrical",
                "Heating",
                "Appliance",
                "Other"
              ]
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c)))
                  .toList(),

              onChanged: (value) =>
                  setState(() => selectedCategory = value),

              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 20),

            _sectionTitle("Describe the problem"),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 20),

            _sectionTitle("Urgency"),

            DropdownButtonFormField<String>(
              items: ["Low", "Medium", "High"]
                  .map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(u)))
                  .toList(),

              onChanged: (value) =>
                  setState(() => selectedUrgency = value),

              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 20),

            _sectionTitle("Entry Permission"),

            DropdownButtonFormField<String>(
              items: [
                "Allow entry if not home",
                "Do not allow entry"
              ]
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e)))
                  .toList(),

              onChanged: (value) =>
                  setState(() => entryPermission = value),

              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                minimumSize: const Size(double.infinity, 50),
              ),

              onPressed: () async {

                if (selectedCategory == null ||
                    selectedUrgency == null ||
                    entryPermission == null ||
                    descriptionController.text.isEmpty) {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Please fill all required fields")),
                  );
                  return;
                }

                String dateKey =
                    "${widget.date.year}-${widget.date.month}-${widget.date.day}";

                try {

                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .add({

                    "date": dateKey,
                    "slot": widget.slot,
                    "category": selectedCategory,
                    "urgency": selectedUrgency,
                    "entryPermission": entryPermission,
                    "description":
                        descriptionController.text,
                    "createdAt":
                        FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text("Request Submitted")),
                  );

                  Navigator.pop(context);

                } catch (e) {

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Error: $e")),
                  );

                }
              },

              child: const Text(
                "Submit Request",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.darkGreen,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
      ),
      contentPadding:
          const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10),
    );
  }
}