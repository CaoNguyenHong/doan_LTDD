import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../screens/main_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_aware_provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/recurring_provider.dart';
import 'auth_repo.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepo();

    // Force logout on app start for testing - DISABLED
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   try {
    //     await authRepo.signOut();
    //     print('AuthGate: Force logged out for testing');
    //   } catch (e) {
    //     print('AuthGate: Error during force logout: $e');
    //   }
    // });

    return StreamBuilder<User?>(
      stream: authRepo.stream,
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

        // If user is signed in, show main app
        if (snapshot.hasData && snapshot.data != null) {
          print('AuthGate: User is signed in, showing MainScreen');
          print('AuthGate: User UID = ${snapshot.data!.uid}');
          print('AuthGate: User email = ${snapshot.data!.email}');

          // FORCE LOGOUT FOR TESTING - DISABLED
          // WidgetsBinding.instance.addPostFrameCallback((_) async {
          //   try {
          //     await authRepo.signOut();
          //     print('AuthGate: Force logged out user for testing');
          //   } catch (e) {
          //     print('AuthGate: Error during force logout: $e');
          //   }
          // });

          // Update all user-aware providers with new UID
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Update ExpenseProvider
            final expenseProviderWrapper =
                Provider.of<UserAwareProvider<ExpenseProvider>>(context,
                    listen: false);
            expenseProviderWrapper.updateUser();

            // Update SettingsProvider
            final settingsProviderWrapper =
                Provider.of<UserAwareProvider<SettingsProvider>>(context,
                    listen: false);
            settingsProviderWrapper.updateUser();

            // Update AccountProvider
            final accountProviderWrapper =
                Provider.of<UserAwareProvider<AccountProvider>>(context,
                    listen: false);
            accountProviderWrapper.updateUser();

            // Update TransactionProvider
            final transactionProviderWrapper =
                Provider.of<UserAwareProvider<TransactionProvider>>(context,
                    listen: false);
            transactionProviderWrapper.updateUser();

            // Update BudgetProvider
            final budgetProviderWrapper =
                Provider.of<UserAwareProvider<BudgetProvider>>(context,
                    listen: false);
            budgetProviderWrapper.updateUser();

            // Update RecurringProvider
            final recurringProviderWrapper =
                Provider.of<UserAwareProvider<RecurringProvider>>(context,
                    listen: false);
            recurringProviderWrapper.updateUser();
          });
          return const MainScreen(key: ValueKey('main_screen'));
        }

        // If user is not signed in, show welcome screen
        print('AuthGate: User is not signed in, showing WelcomeScreen');
        return const WelcomeScreen(key: ValueKey('welcome_screen'));
      },
    );
  }
}
