import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/firestore_data_source.dart';

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final FirestoreDataSource _firestoreDataSource = FirestoreDataSource();
  String? _uid;

  bool _isDarkMode = false;
  String _currency = 'USD';
  String _userName = '';
  double _monthlyIncome = 0.0;
  double _dailyLimit = 0.0;
  double _weeklyLimit = 0.0;
  double _monthlyLimit = 0.0;
  double _yearlyLimit = 0.0;

  SettingsProvider(this._prefs) {
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;
  String get userName => _userName;
  double get monthlyIncome => _monthlyIncome;
  double get dailyLimit => _dailyLimit;
  double get weeklyLimit => _weeklyLimit;
  double get monthlyLimit => _monthlyLimit;
  double get yearlyLimit => _yearlyLimit;

  /// Load settings from Firestore with fallback to SharedPreferences
  void _loadSettings() {
    if (_uid == null) {
      _loadFromLocal();
      return;
    }

    _firestoreDataSource.watchSettings(_uid!).listen((settings) {
      if (settings != null) {
        _isDarkMode = settings['darkMode'] ?? false;
        _currency = settings['currency'] ?? 'USD';
        _userName = settings['userName'] ?? _generateDefaultUsername();
        _monthlyIncome = (settings['monthlyIncome'] ?? 0.0).toDouble();
        _dailyLimit = (settings['dailyLimit'] ?? 0.0).toDouble();
        _weeklyLimit = (settings['weeklyLimit'] ?? 0.0).toDouble();
        _monthlyLimit = (settings['monthlyLimit'] ?? 0.0).toDouble();
        _yearlyLimit = (settings['yearlyLimit'] ?? 0.0).toDouble();
        notifyListeners();
      } else {
        _loadFromLocal();
      }
    });
  }

  /// Load settings from local SharedPreferences
  void _loadFromLocal() {
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    _currency = _prefs.getString('currency') ?? 'USD';
    _userName = _prefs.getString('userName') ?? _generateDefaultUsername();
    _monthlyIncome = _prefs.getDouble('monthlyIncome') ?? 0.0;
    _dailyLimit = _prefs.getDouble('dailyLimit') ?? 0.0;
    _weeklyLimit = _prefs.getDouble('weeklyLimit') ?? 0.0;
    _monthlyLimit = _prefs.getDouble('monthlyLimit') ?? 0.0;
    _yearlyLimit = _prefs.getDouble('yearlyLimit') ?? 0.0;
    notifyListeners();
  }

  static String _generateDefaultUsername() {
    final random = Random();
    final number = random.nextInt(9999).toString().padLeft(4, '0');
    return 'User$number';
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool('isDarkMode', value);
    
    if (_uid != null) {
      await _firestoreDataSource.updateSettings(_uid!, {'darkMode': value});
    }
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    await _prefs.setString('currency', value);
    
    if (_uid != null) {
      await _firestoreDataSource.updateSettings(_uid!, {'currency': value});
    }
    notifyListeners();
  }

  Future<void> setUserName(String value) async {
    _userName = value;
    await _prefs.setString('userName', value);
    
    if (_uid != null) {
      await _firestoreDataSource.updateSettings(_uid!, {'userName': value});
    }
    notifyListeners();
  }

  Future<void> setMonthlyIncome(double value) async {
    _monthlyIncome = value;
    await _prefs.setDouble('monthlyIncome', value);
    
    if (_uid != null) {
      await _firestoreDataSource.updateSettings(_uid!, {'monthlyIncome': value});
    }
    notifyListeners();
  }

  Future<void> setDailyLimit(double value) async {
    _dailyLimit = value;
    await _prefs.setDouble('dailyLimit', value);
    
    if (_uid != null) {
      await _firestoreDataSource.updateSettings(_uid!, {'dailyLimit': value});
    }
    notifyListeners();
  }

  Future<void> setWeeklyLimit(double value) async {
    _weeklyLimit = value;
    await _prefs.setDouble('weeklyLimit', value);
    
    if (_uid != null) {
      await _firestoreDataSource.updateSettings(_uid!, {'weeklyLimit': value});
    }
    notifyListeners();
  }

  Future<void> setMonthlyLimit(double value) async {
    _monthlyLimit = value;
    await _prefs.setDouble('monthlyLimit', value);
    
    if (_uid != null) {
      await _firestoreDataSource.updateSettings(_uid!, {'monthlyLimit': value});
    }
    notifyListeners();
  }

  Future<void> setYearlyLimit(double value) async {
    _yearlyLimit = value;
    await _prefs.setDouble('yearlyLimit', value);
    
    if (_uid != null) {
      await _firestoreDataSource.updateSettings(_uid!, {'yearlyLimit': value});
    }
    notifyListeners();
  }

  AlertStatus getAlertStatus(double currentAmount, double limit) {
    if (limit <= 0) return AlertStatus.none;

    final percentage = (currentAmount / limit) * 100;

    if (percentage >= 100) {
      return AlertStatus.critical;
    } else if (percentage >= 75) {
      return AlertStatus.warning;
    } else if (percentage >= 50) {
      return AlertStatus.caution;
    }
    return AlertStatus.normal;
  }

  String getAlertMessage(double currentAmount, double limit) {
    if (limit <= 0) return '';

    final percentage = (currentAmount / limit) * 100;
    final remaining = limit - currentAmount;

    if (percentage >= 100) {
      return 'Exceeded limit by ${currency}${(currentAmount - limit).toStringAsFixed(2)}';
    } else if (percentage >= 75) {
      return '${currency}${remaining.toStringAsFixed(2)} remaining';
    } else if (percentage >= 50) {
      return '${currency}${remaining.toStringAsFixed(2)} remaining';
    }
    return '';
  }
}

enum AlertStatus {
  none,
  normal,
  caution,
  warning,
  critical,
}
