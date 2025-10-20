import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/main_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import 'auth_repo.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Temporarily bypass authentication for development
    // In production, uncomment the code below and remove the direct return
    return const MainScreen();

    /*
    final authRepo = AuthRepo();
    
    return StreamBuilder<User?>(
      stream: authRepo.stream,
      builder: (context, snapshot) {
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
          return const MainScreen();
        }

        // If user is not signed in, show sign in screen
        return const SignInScreen();
      },
    );
    */
  }
}
