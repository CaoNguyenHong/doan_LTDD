import 'package:flutter/material.dart';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;

  bool _isDarkMode;
  String _currency;
  String _userName;
  double _monthlyIncome;
  double _dailyLimit;
  double _weeklyLimit;
  double _monthlyLimit;
  double _yearlyLimit;

  SettingsProvider(this._prefs)
      : _isDarkMode = _prefs.getBool('isDarkMode') ?? false,
        _currency = _prefs.getString('currency') ?? 'USD',
        _userName = _prefs.getString('userName') ?? _generateDefaultUsername(),
        _monthlyIncome = _prefs.getDouble('monthlyIncome') ?? 0.0,
        _dailyLimit = _prefs.getDouble('dailyLimit') ?? 0.0,
        _weeklyLimit = _prefs.getDouble('weeklyLimit') ?? 0.0,
        _monthlyLimit = _prefs.getDouble('monthlyLimit') ?? 0.0,
        _yearlyLimit = _prefs.getDouble('yearlyLimit') ?? 0.0;

  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;
  String get userName => _userName;
  double get monthlyIncome => _monthlyIncome;
  double get dailyLimit => _dailyLimit;
  double get weeklyLimit => _weeklyLimit;
  double get monthlyLimit => _monthlyLimit;
  double get yearlyLimit => _yearlyLimit;

  static String _generateDefaultUsername() {
    final random = Random();
    final number = random.nextInt(9999).toString().padLeft(4, '0');
    return 'User$number';
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    await _prefs.setString('currency', value);
    notifyListeners();
  }

  Future<void> setUserName(String value) async {
    _userName = value;
    await _prefs.setString('userName', value);
    notifyListeners();
  }

  Future<void> setMonthlyIncome(double value) async {
    _monthlyIncome = value;
    await _prefs.setDouble('monthlyIncome', value);
    notifyListeners();
  }

  Future<void> setDailyLimit(double value) async {
    _dailyLimit = value;
    await _prefs.setDouble('dailyLimit', value);
    notifyListeners();
  }

  Future<void> setWeeklyLimit(double value) async {
    _weeklyLimit = value;
    await _prefs.setDouble('weeklyLimit', value);
    notifyListeners();
  }

  Future<void> setMonthlyLimit(double value) async {
    _monthlyLimit = value;
    await _prefs.setDouble('monthlyLimit', value);
    notifyListeners();
  }

  Future<void> setYearlyLimit(double value) async {
    _yearlyLimit = value;
    await _prefs.setDouble('yearlyLimit', value);
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
