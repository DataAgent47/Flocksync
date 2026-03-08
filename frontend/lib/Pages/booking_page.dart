import 'package:flutter/material.dart';

class BookingPage extends StatefulWidget {
  final int day;
  final String slot;

  const BookingPage({super.key, required this.day, required this.slot});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final Color primaryGreen = Color(0xFF2E7D67);
  final Color backgroundColor = Color(0xFFF5F1EC);
  final Color primaryText = Color(0xFF1A2A36);

  String? selectedCategory;
  String? selectedUrgency;
  String? entryPermission;

  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text("Book Maintenance"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 📅 Selected date + time
            Text(
              "April ${widget.day}, 2026 • ${widget.slot}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 20),

            // 🛠 CATEGORY
            _sectionTitle("Category"),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: ["Plumbing", "Electrical", "Heating", "Appliance", "Other"]
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategory = value),
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 20),

            // 📝 DESCRIPTION
            _sectionTitle("Describe the problem"),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 20),

            // 📷 PHOTO UPLOAD (UI placeholder)
            _sectionTitle("Upload Photo (optional)"),
            GestureDetector(
              onTap: () {
                // later: image picker
              },
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ⚡ URGENCY
            _sectionTitle("Urgency"),
            DropdownButtonFormField<String>(
              value: selectedUrgency,
              items: ["Low", "Medium", "High"]
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (value) => setState(() => selectedUrgency = value),
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 20),

            // 🚪 ENTRY PERMISSION
            _sectionTitle("Entry Permission"),
            DropdownButtonFormField<String>(
              value: entryPermission,
              items: [
                "Allow entry if not home",
                "Do not allow entry"
              ]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => entryPermission = value),
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 30),

            // ✅ SUBMIT BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                if (selectedCategory == null ||
                    selectedUrgency == null ||
                    entryPermission == null ||
                    descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all required fields")),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Request Submitted")),
                );
              },
              child: const Text(
                "Submit Request",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Helpers

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: primaryText,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}