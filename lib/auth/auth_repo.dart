import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // TODO(CURSOR): Fix Google Sign-in

class AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn(); // TODO(CURSOR): Fix Google Sign-in

  /// Stream of authentication state changes
  Stream<User?> get stream => _auth.authStateChanges();

  /// Current user
  User? get user => _auth.currentUser;

  /// Sign up with email and password and create user profile
  Future<UserCredential> signUpAndCreateProfile({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      final userDoc = _firestore.collection('users').doc(uid);

      // Create user profile (idempotent)
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(userDoc);
        if (!snap.exists) {
          tx.set(userDoc, {
            'displayName': displayName ?? '',
            'currency': 'VND', // TODO(CURSOR): Set default currency
            'darkMode': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Update displayName (optional)
      if (displayName != null && displayName.isNotEmpty) {
        await cred.user!.updateDisplayName(displayName);
      }

      return cred;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign up with email and password (legacy method)
  Future<UserCredential> signUpEmail(String email, String password) async {
    return signUpAndCreateProfile(email: email, password: password);
  }

  /// Sign in with email and password
  Future<UserCredential> signInEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  /// TODO(CURSOR): Fix Google Sign-in implementation
  Future<UserCredential> signInGoogle() async {
    throw Exception(
        'Google Sign-in not implemented yet. Please use email/password authentication.');
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    // await _googleSignIn.signOut(); // TODO(CURSOR): Fix Google Sign-in
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
