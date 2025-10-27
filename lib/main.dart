import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_sage/auth/auth_gate.dart';
import 'package:spend_sage/service/api_service.dart';
import 'package:spend_sage/widgets/app_lifecycle_manager.dart';
import 'firebase_options.dart';

// Global Navigator Key để có thể navigate từ bất kỳ đâu
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase App Check (Debug only)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize AI Service
  final aiService = AIService();

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        Provider<AIService>.value(value: aiService),
      ],
      child: const AppLifecycleManager(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Sử dụng global navigator key
      title: 'SpendSage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
