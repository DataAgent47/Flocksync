import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_colors.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flocksync Auth Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: AppColors.darkGreen,
          onPrimary: AppColors.background,
          secondary: AppColors.green2,
          onSecondary: AppColors.background,
          surface: AppColors.background,
          onSurface: AppColors.darkGreen,
          error: AppColors.darkGreen,
          onError: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.darkGreen,
          elevation: 0,
        ),
      ),
      home: const Authtest(),
    );
  }
}


class Authtest extends StatelessWidget {
  const Authtest({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a splash/loading indicator while the stream connects
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Home or login based on auth state
        final user = snapshot.data;
        if (user != null) {
          // Require email verification for email/password users
          final isEmailPasswordUser =
              user.providerData.any((info) => info.providerId == 'password');
          if (isEmailPasswordUser && !user.emailVerified) {
            // Briefly shown while the signup/login flow signs the user out
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return HomeScreen(user: user);
        }
        return const LoginScreen();
      },
    );
  }
}
