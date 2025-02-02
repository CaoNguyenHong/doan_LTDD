import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_sage/providers/expense_provider.dart';
import 'package:spend_sage/providers/settings_provider.dart';
import 'package:spend_sage/screens/main_screen.dart';
import 'package:spend_sage/service/api_service.dart';
import 'package:spend_sage/service/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize services
  final prefs = await SharedPreferences.getInstance();
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
          create: (context) => ExpenseProvider(
            databaseService: databaseService,
            aiService: aiService,
          ),
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
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: const MainScreen(),
        ),
      ),
    );
  }
}
