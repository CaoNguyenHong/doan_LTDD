import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_sage/providers/expense_provider.dart';
import 'package:spend_sage/providers/settings_provider.dart';
import 'package:spend_sage/auth/auth_gate.dart';
import 'package:spend_sage/service/api_service.dart';
import 'package:spend_sage/service/database_service.dart';
import 'firebase_options.dart';

Future<void> _initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Use Firebase Emulator for development
  if (kDebugMode) {
    try {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      print('🔥 Using Firebase Emulator');
    } catch (e) {
      print('⚠️ Firebase Emulator not available: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await _initFirebase();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  // TODO(CURSOR): Keep Hive service for migration, remove when fully migrated
  final databaseService = DatabaseService();
  await databaseService.init();

  final aiService = AIService(
    apiKey: dotenv.env['GOOGLE_API_KEY'] ?? '',
  );

  runApp(MyApp(
    databaseService: databaseService,
    aiService: aiService,
    prefs: prefs,
  ));
}

class MyApp extends StatelessWidget {
  final DatabaseService databaseService;
  final AIService aiService;
  final SharedPreferences prefs;

  const MyApp({
    super.key,
    required this.databaseService,
    required this.aiService,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ExpenseProvider.firestore(), // Use Firestore
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsProvider(prefs),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'SpendSage',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal, // Updated to match Firebase theme
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal, // Updated to match Firebase theme
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: const AuthGate(), // Use AuthGate instead of MainScreen
        ),
      ),
    );
  }
}
