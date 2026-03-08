import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Pages/maintenance_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FlockSyncApp());
}

class FlockSyncApp extends StatelessWidget {
  const FlockSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "FlockSync",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D67),
      ),
      home: const MaintenancePage(),
    );
  }
}