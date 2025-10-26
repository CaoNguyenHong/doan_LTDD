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
import 'package:spend_sage/providers/user_aware_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spend_sage/auth/auth_gate.dart';
import 'package:spend_sage/screens/main_screen.dart';
import 'package:spend_sage/service/api_service.dart';
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

  final aiService = AIService(
    apiKey: const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
  );

  runApp(MyApp(
    aiService: aiService,
    prefs: prefs,
  ));

  // TODO(CURSOR): Bật auth gate sau khi setup Firebase xong
  // Thay MyApp bằng AuthGate để enable authentication
}

class MyApp extends StatelessWidget {
  final AIService aiService;
  final SharedPreferences prefs;

  const MyApp({
    super.key,
    required this.aiService,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // User-aware providers that recreate when user changes
        ChangeNotifierProvider<UserAwareProvider<ExpenseProvider>>(
          create: (context) => UserAwareProvider<ExpenseProvider>(
            (uid) => ExpenseProvider.firestore(),
          ),
        ),
        ChangeNotifierProvider<UserAwareProvider<SettingsProvider>>(
          create: (context) => UserAwareProvider<SettingsProvider>(
            (uid) => SettingsProvider(prefs),
          ),
        ),
        ChangeNotifierProvider<UserAwareProvider<AccountProvider>>(
          create: (context) => UserAwareProvider<AccountProvider>(
            (uid) => AccountProvider(uid: uid),
          ),
        ),
        ChangeNotifierProvider<UserAwareProvider<TransactionProvider>>(
          create: (context) => UserAwareProvider<TransactionProvider>(
            (uid) => TransactionProvider(uid: uid),
          ),
        ),
        ChangeNotifierProvider<UserAwareProvider<BudgetProvider>>(
          create: (context) => UserAwareProvider<BudgetProvider>(
            (uid) => BudgetProvider(uid: uid),
          ),
        ),
        ChangeNotifierProvider<UserAwareProvider<RecurringProvider>>(
          create: (context) => UserAwareProvider<RecurringProvider>(
            (uid) => RecurringProvider(uid: uid),
          ),
        ),

        // Proxy providers for backward compatibility
        ChangeNotifierProxyProvider<UserAwareProvider<ExpenseProvider>,
            ExpenseProvider>(
          create: (context) {
            final wrapper = Provider.of<UserAwareProvider<ExpenseProvider>>(
                context,
                listen: false);
            return wrapper.provider;
          },
          update: (context, wrapper, previous) => wrapper.provider,
        ),
        ChangeNotifierProxyProvider<UserAwareProvider<SettingsProvider>,
            SettingsProvider>(
          create: (context) {
            final wrapper = Provider.of<UserAwareProvider<SettingsProvider>>(
                context,
                listen: false);
            return wrapper.provider;
          },
          update: (context, wrapper, previous) => wrapper.provider,
        ),
        ChangeNotifierProxyProvider<UserAwareProvider<AccountProvider>,
            AccountProvider>(
          create: (context) {
            final wrapper = Provider.of<UserAwareProvider<AccountProvider>>(
                context,
                listen: false);
            return wrapper.provider;
          },
          update: (context, wrapper, previous) => wrapper.provider,
        ),
        ChangeNotifierProxyProvider<UserAwareProvider<TransactionProvider>,
            TransactionProvider>(
          create: (context) {
            final wrapper = Provider.of<UserAwareProvider<TransactionProvider>>(
                context,
                listen: false);
            return wrapper.provider;
          },
          update: (context, wrapper, previous) => wrapper.provider,
        ),
        ChangeNotifierProxyProvider<UserAwareProvider<BudgetProvider>,
            BudgetProvider>(
          create: (context) {
            final wrapper = Provider.of<UserAwareProvider<BudgetProvider>>(
                context,
                listen: false);
            return wrapper.provider;
          },
          update: (context, wrapper, previous) => wrapper.provider,
        ),
        ChangeNotifierProxyProvider<UserAwareProvider<RecurringProvider>,
            RecurringProvider>(
          create: (context) {
            final wrapper = Provider.of<UserAwareProvider<RecurringProvider>>(
                context,
                listen: false);
            return wrapper.provider;
          },
          update: (context, wrapper, previous) => wrapper.provider,
        ),

        // Proxy providers that depend on user-aware providers
        ChangeNotifierProxyProvider2<UserAwareProvider<ExpenseProvider>,
            UserAwareProvider<SettingsProvider>, AnalyticsProvider>(
          create: (context) {
            final expenseProviderWrapper =
                Provider.of<UserAwareProvider<ExpenseProvider>>(context,
                    listen: false);
            return AnalyticsProvider(expenseProviderWrapper.provider);
          },
          update: (context, expenseProviderWrapper, settingsProviderWrapper,
              previous) {
            return previous ??
                AnalyticsProvider(expenseProviderWrapper.provider);
          },
        ),
        ChangeNotifierProxyProvider2<UserAwareProvider<ExpenseProvider>,
            UserAwareProvider<SettingsProvider>, NotificationProvider>(
          create: (context) {
            final expenseProviderWrapper =
                Provider.of<UserAwareProvider<ExpenseProvider>>(context,
                    listen: false);
            final settingsProviderWrapper =
                Provider.of<UserAwareProvider<SettingsProvider>>(context,
                    listen: false);
            return NotificationProvider(expenseProviderWrapper.provider,
                settingsProviderWrapper.provider);
          },
          update: (context, expenseProviderWrapper, settingsProviderWrapper,
              previous) {
            return previous ??
                NotificationProvider(expenseProviderWrapper.provider,
                    settingsProviderWrapper.provider);
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'SpendSage',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal, // Updated to match Firebase theme
              brightness:
                  settings.isDarkMode ? Brightness.dark : Brightness.light,
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
