// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_sage/main.dart';
import 'package:spend_sage/service/database_service.dart';
import 'package:spend_sage/service/api_service.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Mock services
    final databaseService = DatabaseService();
    await databaseService.init();
    final aiService = AIService(apiKey: 'test-key');

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      databaseService: databaseService,
      aiService: aiService,
      prefs: prefs,
    ));

    // Verify that the app loads (should show AuthGate or SignInScreen)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
