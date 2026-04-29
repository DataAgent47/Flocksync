import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flocksync/core/theme/flock_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

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

  XFile? _imageFile;
  Uint8List? _imageBytes;

  bool _isSubmitting = false;

  // Pick image (preview only)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        _imageBytes = await picked.readAsBytes();
      }

      if (!mounted) return;

      setState(() {
        _imageFile = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (selectedCategory == null ||
        selectedUrgency == null ||
        entryPermission == null ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final dateKey =
        "${widget.date.year}-${widget.date.month}-${widget.date.day}";

    try {
      // No upload (keep null placeholder)
      final imageUrl = null;

      await FirebaseFirestore.instance.collection('bookings').add({
        "date": dateKey,
        "slot": widget.slot,
        "category": selectedCategory,
        "urgency": selectedUrgency,
        "entryPermission": entryPermission,
        "description": descriptionController.text,
        "imageUrl": imageUrl,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const SizedBox(
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Success",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text("Your booking has been submitted."),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
              items: ["Plumbing", "Electrical", "Heating", "Appliance", "Other"]
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v),
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
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) => setState(() => selectedUrgency = v),
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 20),

            _sectionTitle("Entry Permission"),
            DropdownButtonFormField<String>(
              items: [
                "Allow entry if not home",
                "Do not allow entry"
              ]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => entryPermission = v),
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 20),

            _sectionTitle("Upload Photo (optional)"),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageFile == null
                    ? const Center(
                        child: Icon(Icons.camera_alt,
                            size: 40, color: Colors.grey),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : Image.network(_imageFile!.path, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Submit Request",
                      style: TextStyle(fontSize: 16, color: Colors.white),
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
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}