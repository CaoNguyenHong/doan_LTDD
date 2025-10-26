import 'package:flutter/material.dart';
import '../data/firestore_data_source.dart';
import '../service/currency_service.dart';

class SettingsProvider extends ChangeNotifier {
  final FirestoreDataSource _ds;
  final String _uid;

  SettingsProvider(this._ds, this._uid) {
    _watch();
  }

  bool _isDarkMode = false;
  String _currency = 'VND'; // TODO(CURSOR): Set default currency
  String _previousCurrency = 'VND';
  String _userName = '';
  double _monthlyIncome = 0.0;
  double _dailyLimit = 0.0;
  double _weeklyLimit = 0.0;
  double _monthlyLimit = 0.0;
  double _yearlyLimit = 0.0;
  double _exchangeRate = 1.0;
  bool _loading = true;
  String? _error;

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
  bool get isLoading => _loading;
  String? get error => _error;

  void _watch() {
    _loading = true;
    notifyListeners();
    _ds.watchSettings(_uid).listen((data) {
      if (data != null) {
        _isDarkMode = data['darkMode'] ?? false;
        _currency = data['currency'] ?? 'VND';
        _userName = data['displayName'] ?? '';
        _monthlyIncome = (data['monthlyIncome'] ?? 0.0).toDouble();
        _dailyLimit = (data['dailyLimit'] ?? 0.0).toDouble();
        _weeklyLimit = (data['weeklyLimit'] ?? 0.0).toDouble();
        _monthlyLimit = (data['monthlyLimit'] ?? 0.0).toDouble();
        _yearlyLimit = (data['yearlyLimit'] ?? 0.0).toDouble();
        _exchangeRate = (data['exchangeRate'] ?? 1.0).toDouble();
      }
      _loading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await _ds.updateSettings(_uid, settings);
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await updateSettings({'darkMode': _isDarkMode});
    notifyListeners();
  }

  Future<void> setCurrency(String newCurrency) async {
    if (newCurrency == _currency) return;

    _previousCurrency = _currency;
    _currency = newCurrency;

    // Update exchange rate
    await _updateExchangeRate();

    await updateSettings({
      'currency': _currency,
      'previousCurrency': _previousCurrency,
      'exchangeRate': _exchangeRate,
    });
    notifyListeners();
  }

  Future<void> _updateExchangeRate() async {
    try {
      _exchangeRate =
          await CurrencyService.getExchangeRate(_previousCurrency, _currency);
    } catch (e) {
      print('Error updating exchange rate: $e');
      _exchangeRate = 1.0; // Fallback to 1.0
    }
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    await updateSettings({'displayName': _userName});
    notifyListeners();
  }

  Future<void> setMonthlyIncome(double income) async {
    _monthlyIncome = income;
    await updateSettings({'monthlyIncome': _monthlyIncome});
    notifyListeners();
  }

  Future<void> setDailyLimit(double limit) async {
    _dailyLimit = limit;
    await updateSettings({'dailyLimit': _dailyLimit});
    notifyListeners();
  }

  Future<void> setWeeklyLimit(double limit) async {
    _weeklyLimit = limit;
    await updateSettings({'weeklyLimit': _weeklyLimit});
    notifyListeners();
  }

  Future<void> setMonthlyLimit(double limit) async {
    _monthlyLimit = limit;
    await updateSettings({'monthlyLimit': _monthlyLimit});
    notifyListeners();
  }

  Future<void> setYearlyLimit(double limit) async {
    _yearlyLimit = limit;
    await updateSettings({'yearlyLimit': _yearlyLimit});
    notifyListeners();
  }

  Future<void> setExchangeRate(double rate) async {
    _exchangeRate = rate;
    await updateSettings({'exchangeRate': _exchangeRate});
    notifyListeners();
  }

  // Calculation methods
  double convertAmount(double amount) {
    return amount * _exchangeRate;
  }

  double convertFromPreviousCurrency(double amount) {
    return amount * _exchangeRate;
  }

  double convertToPreviousCurrency(double amount) {
    return amount / _exchangeRate;
  }

  // Limit calculation methods
  double getSuggestedDailyLimit() {
    if (_monthlyIncome == 0) return 0.0;
    return _monthlyIncome / 30; // Rough daily limit based on monthly income
  }

  double getSuggestedWeeklyLimit() {
    if (_monthlyIncome == 0) return 0.0;
    return _monthlyIncome / 4; // Rough weekly limit based on monthly income
  }

  double getSuggestedMonthlyLimit() {
    return _monthlyIncome * 0.8; // 80% of monthly income as spending limit
  }

  double getSuggestedYearlyLimit() {
    if (_monthlyIncome == 0) return 0.0;
    return _monthlyIncome * 12 * 0.8; // 80% of yearly income as spending limit
  }

  // Validation methods
  bool isValidLimit(double limit) {
    return limit >= 0 && limit <= _monthlyIncome * 12; // Max yearly income
  }

  bool isValidIncome(double income) {
    return income >= 0 && income <= 10000000; // Max 10M per month
  }

  // Statistics methods
  Map<String, double> getAllLimits() {
    return {
      'daily': _dailyLimit,
      'weekly': _weeklyLimit,
      'monthly': _monthlyLimit,
      'yearly': _yearlyLimit,
    };
  }

  Map<String, double> getSuggestedLimits() {
    return {
      'daily': getSuggestedDailyLimit(),
      'weekly': getSuggestedWeeklyLimit(),
      'monthly': getSuggestedMonthlyLimit(),
      'yearly': getSuggestedYearlyLimit(),
    };
  }

  // Currency methods
  List<String> getSupportedCurrencies() {
    return [
      'VND',
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'KRW',
      'CNY'
    ]; // TODO(CURSOR): Add more currencies
  }

  String getCurrencySymbol() {
    switch (_currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'CNY':
        return '¥';
      case 'VND':
        return '₫';
      default:
        return _currency;
    }
  }

  // Theme methods
  ThemeMode getThemeMode() {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Brightness getBrightness() {
    return _isDarkMode ? Brightness.dark : Brightness.light;
  }

  // Additional methods for backward compatibility
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await updateSettings({'darkMode': _isDarkMode});
    notifyListeners();
  }

  double getSpendingLimit(String period) {
    switch (period.toLowerCase()) {
      case 'daily':
        return _dailyLimit;
      case 'weekly':
        return _weeklyLimit;
      case 'monthly':
        return _monthlyLimit;
      case 'yearly':
        return _yearlyLimit;
      default:
        return _monthlyLimit;
    }
  }

  // Reset methods
  Future<void> resetToDefaults() async {
    _isDarkMode = false;
    _currency = 'VND';
    _previousCurrency = 'VND';
    _userName = '';
    _monthlyIncome = 0.0;
    _dailyLimit = 0.0;
    _weeklyLimit = 0.0;
    _monthlyLimit = 0.0;
    _yearlyLimit = 0.0;
    _exchangeRate = 1.0;

    await updateSettings({
      'darkMode': _isDarkMode,
      'currency': _currency,
      'previousCurrency': _previousCurrency,
      'displayName': _userName,
      'monthlyIncome': _monthlyIncome,
      'dailyLimit': _dailyLimit,
      'weeklyLimit': _weeklyLimit,
      'monthlyLimit': _monthlyLimit,
      'yearlyLimit': _yearlyLimit,
      'exchangeRate': _exchangeRate,
    });
    notifyListeners();
  }

  // Additional methods for backward compatibility
  Future<void> setDarkModeCompat(bool isDark) async {
    _isDarkMode = isDark;
    await updateSettings({'darkMode': _isDarkMode});
    notifyListeners();
  }

  double getSpendingLimitCompat(String period) {
    switch (period.toLowerCase()) {
      case 'daily':
        return _dailyLimit;
      case 'weekly':
        return _weeklyLimit;
      case 'monthly':
        return _monthlyLimit;
      case 'yearly':
        return _yearlyLimit;
      default:
        return _monthlyLimit;
    }
  }

  // Reset methods
  Future<void> resetToDefaultsCompat() async {
    _isDarkMode = false;
    _currency = 'VND';
    _previousCurrency = 'VND';
    _userName = '';
    _monthlyIncome = 0.0;
    _dailyLimit = 0.0;
    _weeklyLimit = 0.0;
    _monthlyLimit = 0.0;
    _yearlyLimit = 0.0;
    _exchangeRate = 1.0;
    await updateSettings({
      'darkMode': _isDarkMode,
      'currency': _currency,
      'previousCurrency': _previousCurrency,
      'displayName': _userName,
      'monthlyIncome': _monthlyIncome,
      'dailyLimit': _dailyLimit,
      'weeklyLimit': _weeklyLimit,
      'monthlyLimit': _monthlyLimit,
      'yearlyLimit': _yearlyLimit,
      'exchangeRate': _exchangeRate,
    });
    notifyListeners();
  }
}
