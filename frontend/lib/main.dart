import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/maintenance_page.dart';
import 'color.dart';

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
        primaryColor: AppColors.darkGreen,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.darkGreen,
        ),
      ),

      home: const MaintenancePage(),
    );
  }
}