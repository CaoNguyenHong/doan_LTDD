import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/firestore_data_source.dart';
import '../service/currency_service.dart';

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final FirestoreDataSource _firestoreDataSource = FirestoreDataSource();
  String? _uid;

  bool _isDarkMode = false;
  String _currency = 'USD';
  String _previousCurrency = 'USD';
  String _userName = '';
  double _monthlyIncome = 0.0;
  double _dailyLimit = 0.0;
  double _weeklyLimit = 0.0;
  double _monthlyLimit = 0.0;
  double _yearlyLimit = 0.0;
  double _exchangeRate = 1.0;

  SettingsProvider(this._prefs) {
    _initializeWithCurrentUser();
  }

  /// Initialize with current user
  void _initializeWithCurrentUser() {
    _uid = FirebaseAuth.instance.currentUser?.uid;
    print('⚙️ SettingsProvider: Initializing with user UID: $_uid');
    _loadSettings();
  }

  /// Update user when authentication state changes
  void updateUser() {
    print('⚙️ SettingsProvider: Updating user...');
    _initializeWithCurrentUser();
    notifyListeners();
  }

  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;
  String get previousCurrency => _previousCurrency;
  String get userName => _userName;
  double get monthlyIncome => _monthlyIncome;
  double get dailyLimit => _dailyLimit;
  double get weeklyLimit => _weeklyLimit;
  double get monthlyLimit => _monthlyLimit;
  double get yearlyLimit => _yearlyLimit;
  double get exchangeRate => _exchangeRate;

  /// Get spending limit based on period
  double getSpendingLimit(String period) {
    switch (period.toLowerCase()) {
      case 'day':
        return _dailyLimit;
      case 'week':
        return _weeklyLimit;
      case 'month':
        return _monthlyLimit;
      case 'year':
        return _yearlyLimit;
      default:
        return _monthlyLimit;
    }
  }

  /// Get current spending limit (defaults to monthly)
  double get spendingLimit => _monthlyLimit;

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
        _previousCurrency = settings['previousCurrency'] ?? 'USD';
        _userName = settings['userName'] ?? _generateDefaultUsername();
        _monthlyIncome = (settings['monthlyIncome'] ?? 0.0).toDouble();
        _dailyLimit = (settings['dailyLimit'] ?? 0.0).toDouble();
        _weeklyLimit = (settings['weeklyLimit'] ?? 0.0).toDouble();
        _monthlyLimit = (settings['monthlyLimit'] ?? 0.0).toDouble();
        _yearlyLimit = (settings['yearlyLimit'] ?? 0.0).toDouble();
        _exchangeRate = (settings['exchangeRate'] ?? 1.0).toDouble();
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
    _previousCurrency = _prefs.getString('previousCurrency') ?? 'USD';
    _userName = _prefs.getString('userName') ?? _generateDefaultUsername();
    _monthlyIncome = _prefs.getDouble('monthlyIncome') ?? 0.0;
    _dailyLimit = _prefs.getDouble('dailyLimit') ?? 0.0;
    _weeklyLimit = _prefs.getDouble('weeklyLimit') ?? 0.0;
    _monthlyLimit = _prefs.getDouble('monthlyLimit') ?? 0.0;
    _yearlyLimit = _prefs.getDouble('yearlyLimit') ?? 0.0;
    _exchangeRate = _prefs.getDouble('exchangeRate') ?? 1.0;
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
    if (_currency != value) {
      _previousCurrency = _currency;
      _currency = value;

      // Get exchange rate for conversion
      try {
        _exchangeRate =
            await CurrencyService.getExchangeRate(_previousCurrency, _currency);
        print(
            '💱 SettingsProvider: Exchange rate from $_previousCurrency to $value: $_exchangeRate');
      } catch (e) {
        print('💱 SettingsProvider: Error getting exchange rate: $e');
        _exchangeRate = 1.0;
      }

      await _prefs.setString('currency', value);
      await _prefs.setString('previousCurrency', _previousCurrency);
      await _prefs.setDouble('exchangeRate', _exchangeRate);

      if (_uid != null) {
        await _firestoreDataSource.updateSettings(_uid!, {
          'currency': value,
          'previousCurrency': _previousCurrency,
          'exchangeRate': _exchangeRate,
        });
      }
      notifyListeners();
    }
  }

  /// Convert all expenses to new currency (called from UI)
  Future<void> convertExpensesToNewCurrency() async {
    if (_previousCurrency != _currency) {
      // This will be called from the UI when user confirms currency change
      print(
          '💱 SettingsProvider: Converting expenses from $_previousCurrency to $_currency');
    }
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
      await _firestoreDataSource
          .updateSettings(_uid!, {'monthlyIncome': value});
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

  /// Convert amount using current exchange rate
  double convertAmount(double amount) {
    return amount * _exchangeRate;
  }

  /// Get formatted amount with currency symbol
  String getFormattedAmount(double amount) {
    final convertedAmount = convertAmount(amount);
    final symbol = CurrencyService.getCurrencySymbol(_currency);
    return '$symbol${convertedAmount.toStringAsFixed(2)}';
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
      return 'Exceeded limit by $currency${(currentAmount - limit).toStringAsFixed(2)}';
    } else if (percentage >= 75) {
      return '$currency${remaining.toStringAsFixed(2)} remaining';
    } else if (percentage >= 50) {
      return '$currency${remaining.toStringAsFixed(2)} remaining';
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
