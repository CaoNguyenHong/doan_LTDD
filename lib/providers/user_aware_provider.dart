import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

/// A wrapper provider that recreates child providers when the user changes
class UserAwareProvider<T extends ChangeNotifier> extends ChangeNotifier {
  T? _provider;
  String? _currentUid;
  final T Function(String uid) _providerBuilder;

  UserAwareProvider(this._providerBuilder) {
    _initializeProvider();
  }

  void _initializeProvider() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'demo-user';

    if (_currentUid != uid) {
      _currentUid = uid;
      _provider = _providerBuilder(uid);
      print('🔄 UserAwareProvider: Created provider for UID: $uid');
    }
  }

  T get provider {
    _initializeProvider();
    return _provider!;
  }

  void updateUser() {
    print('🔄 UserAwareProvider: Updating user...');
    _initializeProvider();
    notifyListeners();
  }

  @override
  void dispose() {
    _provider?.dispose();
    super.dispose();
  }
}

/// Extension to easily access user-aware providers
extension UserAwareProviderExtension on BuildContext {
  T userAwareProvider<T extends ChangeNotifier>() {
    return Provider.of<UserAwareProvider<T>>(this, listen: false).provider;
  }

  T watchUserAwareProvider<T extends ChangeNotifier>() {
    return Provider.of<UserAwareProvider<T>>(this).provider;
  }
}
