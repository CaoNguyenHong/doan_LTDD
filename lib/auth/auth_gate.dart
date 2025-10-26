import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../screens/main_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../data/firestore_data_source.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/notification_provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Debug: Print authentication state
        print('AuthGate: connectionState = ${snapshot.connectionState}');
        print('AuthGate: hasData = ${snapshot.hasData}');
        print('AuthGate: data = ${snapshot.data}');
        print('AuthGate: error = ${snapshot.error}');

        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          print('AuthGate: User is not signed in, showing WelcomeScreen');
          return const WelcomeScreen(key: ValueKey('welcome_screen'));
        }

        final uid = user.uid;
        print('AuthGate: User is signed in, showing MainScreen');
        print('AuthGate: User UID = $uid');
        print('AuthGate: User email = ${user.email}');

        return MultiProvider(
          providers: [
            Provider(create: (_) => FirestoreDataSource()),
            ChangeNotifierProvider(
              create: (ctx) =>
                  TransactionProvider(ctx.read<FirestoreDataSource>(), uid),
            ),
            ChangeNotifierProvider(
              create: (ctx) =>
                  AccountProvider(ctx.read<FirestoreDataSource>(), uid),
            ),
            ChangeNotifierProvider(
              create: (ctx) =>
                  BudgetProvider(ctx.read<FirestoreDataSource>(), uid),
            ),
            ChangeNotifierProvider(
              create: (ctx) =>
                  RecurringProvider(ctx.read<FirestoreDataSource>(), uid),
            ),
            ChangeNotifierProvider(
              create: (ctx) =>
                  ExpenseProvider(ctx.read<FirestoreDataSource>(), uid),
            ),
            ChangeNotifierProvider(
              create: (ctx) =>
                  SettingsProvider(ctx.read<FirestoreDataSource>(), uid),
            ),
            // TODO(CURSOR): AnalyticsProvider depends on ExpenseProvider
            ChangeNotifierProxyProvider<ExpenseProvider, AnalyticsProvider>(
              create: (ctx) => AnalyticsProvider(ctx.read<ExpenseProvider>()),
              update: (ctx, expenseProvider, previous) =>
                  AnalyticsProvider(expenseProvider),
            ),
            // TODO(CURSOR): NotificationProvider depends on ExpenseProvider and SettingsProvider
            ChangeNotifierProxyProvider2<ExpenseProvider, SettingsProvider,
                NotificationProvider>(
              create: (ctx) => NotificationProvider(
                ctx.read<ExpenseProvider>(),
                ctx.read<SettingsProvider>(),
              ),
              update: (ctx, expenseProvider, settingsProvider, previous) =>
                  NotificationProvider(expenseProvider, settingsProvider),
            ),
          ],
          child: const MainScreen(key: ValueKey('main_screen')),
        );
      },
    );
  }
}
