import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../screens/main_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/pin_screen.dart';
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
        print('AuthGate: connectionState = ${snapshot.connectionState}');
        print('AuthGate: hasData = ${snapshot.hasData}');
        print('AuthGate: data = ${snapshot.data}');
        print('AuthGate: error = ${snapshot.error}');

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
        print(
            'AuthGate: User is signed in, setting up providers with UID: $uid');
        print('AuthGate: User email = ${user.email}');

        // Khởi tạo Providers với UID thực tế
        return MultiProvider(
          providers: [
            Provider(create: (_) => FirestoreDataSource()),
            ChangeNotifierProvider(
              create: (ctx) =>
                  SettingsProvider(ctx.read<FirestoreDataSource>(), uid),
            ),
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
            ChangeNotifierProxyProvider<ExpenseProvider, AnalyticsProvider>(
              create: (ctx) => AnalyticsProvider(ctx.read<ExpenseProvider>()),
              update: (ctx, expenseProvider, previous) =>
                  AnalyticsProvider(expenseProvider),
            ),
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
          child: Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) {
              print('AuthGate: SettingsProvider loaded');
              print('AuthGate: isPinEnabled: ${settingsProvider.isPinEnabled}');
              print('AuthGate: isAppLocked: ${settingsProvider.isAppLocked}');
              print('AuthGate: pinCode: ${settingsProvider.pinCode}');
              print(
                  'AuthGate: shouldShowPinScreen: ${settingsProvider.shouldShowPinScreen()}');

              // Check if PIN is required
              if (settingsProvider.shouldShowPinScreen()) {
                print('AuthGate: Showing PIN screen');
                return PinScreen(
                  settingsProvider: settingsProvider,
                  onSuccess: (pin) async {
                    print(
                        'AuthGate: PIN verified callback triggered with PIN: $pin');
                    print(
                        'AuthGate: Before unlock - isAppLocked: ${settingsProvider.isAppLocked}');
                    await settingsProvider.unlockApp();
                    print(
                        'AuthGate: After unlock - isAppLocked: ${settingsProvider.isAppLocked}');
                    print(
                        'AuthGate: shouldShowPinScreen after unlock: ${settingsProvider.shouldShowPinScreen()}');

                    // Đợi một chút để đảm bảo Firebase update hoàn tất
                    await Future.delayed(const Duration(milliseconds: 100));
                    print(
                        'AuthGate: After delay - shouldShowPinScreen: ${settingsProvider.shouldShowPinScreen()}');
                  },
                );
              }

              // No PIN required or PIN verified, show main screen
              print('AuthGate: Showing main screen');
              return const MainScreen(key: ValueKey('main_screen'));
            },
          ),
        );
      },
    );
  }
}
