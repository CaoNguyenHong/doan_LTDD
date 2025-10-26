import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // TODO(CURSOR): Dùng --dart-define thay vì .env
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_sage/providers/expense_provider.dart';
import 'package:spend_sage/providers/settings_provider.dart';
import 'package:spend_sage/providers/analytics_provider.dart';
import 'package:spend_sage/providers/notification_provider.dart';
import 'package:spend_sage/providers/account_provider.dart';
import 'package:spend_sage/providers/transaction_provider.dart';
import 'package:spend_sage/providers/budget_provider.dart';
import 'package:spend_sage/providers/recurring_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spend_sage/auth/auth_gate.dart';
import 'package:spend_sage/screens/main_screen.dart';
import 'package:spend_sage/service/api_service.dart';
import 'package:spend_sage/service/database_service.dart';
import 'firebase_options.dart';

Future<void> _initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Use Firebase Production for now (emulator has issues)
  print('🔥 Using Firebase Production');

  // TODO: Fix emulator configuration later
  // if (kDebugMode) {
  //   try {
  //     await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  //     FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  //     print('🔥 Using Firebase Emulator');
  //   } catch (e) {
  //     print('⚠️ Firebase Emulator not available: $e');
  //   }
  // }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await _initFirebase();

  // TODO(CURSOR): Dùng --dart-define thay vì .env file
  // await dotenv.load(fileName: ".env");

  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  // TODO(CURSOR): Keep Hive service for migration, remove when fully migrated
  final databaseService = DatabaseService();
  await databaseService.init();

  final aiService = AIService(
    apiKey: const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
  );

  runApp(MyApp(
    databaseService: databaseService,
    aiService: aiService,
    prefs: prefs,
  ));

  // TODO(CURSOR): Bật auth gate sau khi setup Firebase xong
  // Thay MyApp bằng AuthGate để enable authentication
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
        ChangeNotifierProxyProvider2<ExpenseProvider, SettingsProvider,
            AnalyticsProvider>(
          create: (context) => AnalyticsProvider(
            Provider.of<ExpenseProvider>(context, listen: false),
          ),
          update: (context, expenseProvider, settingsProvider, previous) {
            return previous ?? AnalyticsProvider(expenseProvider);
          },
        ),
        ChangeNotifierProxyProvider2<ExpenseProvider, SettingsProvider,
            NotificationProvider>(
          create: (context) => NotificationProvider(
            Provider.of<ExpenseProvider>(context, listen: false),
            Provider.of<SettingsProvider>(context, listen: false),
          ),
          update: (context, expenseProvider, settingsProvider, previous) {
            return previous ??
                NotificationProvider(expenseProvider, settingsProvider);
          },
        ),
        // New providers for enhanced features
        ChangeNotifierProvider(
          create: (context) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              return AccountProvider(uid: user.uid);
            }
            return AccountProvider(uid: 'demo-user');
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              return TransactionProvider(uid: user.uid);
            }
            return TransactionProvider(uid: 'demo-user');
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              return BudgetProvider(uid: user.uid);
            }
            return BudgetProvider(uid: 'demo-user');
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              return RecurringProvider(uid: user.uid);
            }
            return RecurringProvider(uid: 'demo-user');
          },
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
          home: const AuthGate(), // Use AuthGate for authentication
        ),
      ),
    );
  }
}
