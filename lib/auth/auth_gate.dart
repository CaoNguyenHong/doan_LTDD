import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/main_screen.dart';
import '../screens/auth/welcome_screen.dart';
import 'auth_repo.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepo();

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
          return const MainScreen(key: ValueKey('main_screen'));
        }

        // If user is not signed in, show welcome screen
        print('AuthGate: User is not signed in, showing WelcomeScreen');
        return const WelcomeScreen(key: ValueKey('welcome_screen'));
      },
    );
  }
}
