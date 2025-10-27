import 'package:flutter/material.dart';
import 'dart:async';
import '../data/firestore_data_source.dart';
import '../service/currency_service.dart';
import '../models/alert_status.dart';

class SettingsProvider extends ChangeNotifier {
  final FirestoreDataSource _ds;
  final String _uid;
  StreamSubscription<Map<String, dynamic>?>? _settingsSubscription;

  SettingsProvider(this._ds, this._uid) {
    print('SettingsProvider: Initializing with UID: $_uid');
    if (_uid.isEmpty) {
      print('SettingsProvider: WARNING - UID is empty!');
      _error = 'UID is empty';
      _loading = false;
      notifyListeners();
      return;
    }
    _watch();
  }

  @override
  void dispose() {
    print('SettingsProvider: Disposing...');
    _isDisposed = true;
    _settingsSubscription?.cancel();
    super.dispose();
  }

  bool _isDarkMode = false;
  String _currency = 'VND'; // TODO(CURSOR): Set default currency
  String _previousCurrency = 'VND';
  String _userName = '';
  String _phoneNumber = '';
  double _monthlyIncome = 0.0;
  double _dailyLimit = 0.0;
  double _weeklyLimit = 0.0;
  double _monthlyLimit = 0.0;
  double _yearlyLimit = 0.0;
  double _exchangeRate = 1.0;
  bool _loading = true;
  String? _error;

  // PIN Security settings
  String? _pinCode;
  bool _isPinEnabled = false;
  bool _isAppLocked = false;
  bool _hasAutoLocked = false; // Flag để tránh auto-lock nhiều lần
  bool _isDisposed = false; // Flag để kiểm tra disposed
  bool _isInitialized = false; // Flag để kiểm tra đã khởi tạo chưa

  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;
  String get previousCurrency => _previousCurrency;
  String get userName => _userName;
  String get phoneNumber => _phoneNumber;
  double get monthlyIncome => _monthlyIncome;
  double get dailyLimit => _dailyLimit;
  double get weeklyLimit => _weeklyLimit;
  double get monthlyLimit => _monthlyLimit;
  double get yearlyLimit => _yearlyLimit;
  double get exchangeRate => _exchangeRate;
  bool get isLoading => _loading;
  String? get error => _error;

  // PIN Security getters
  String? get pinCode => _pinCode;
  bool get isPinEnabled => _isPinEnabled;
  bool get isAppLocked => _isAppLocked;

  void _watch() {
    _loading = true;
    notifyListeners();
    _settingsSubscription = _ds.watchSettings(_uid).listen((data) {
      // Kiểm tra xem provider đã bị dispose chưa
      if (_isDisposed) {
        print('SettingsProvider: Ignoring data update - provider disposed');
        return;
      }
      if (data != null) {
        _isDarkMode = data['darkMode'] ?? false;
        _currency = data['currency'] ?? 'VND';
        _userName = data['displayName'] ?? '';
        _phoneNumber = data['phoneNumber'] ?? '';
        _monthlyIncome = (data['monthlyIncome'] ?? 0.0).toDouble();
        _dailyLimit = (data['dailyLimit'] ?? 0.0).toDouble();
        _weeklyLimit = (data['weeklyLimit'] ?? 0.0).toDouble();
        _monthlyLimit = (data['monthlyLimit'] ?? 0.0).toDouble();
        _yearlyLimit = (data['yearlyLimit'] ?? 0.0).toDouble();
        _exchangeRate = (data['exchangeRate'] ?? 1.0).toDouble();

        // PIN Security settings
        _pinCode = data['pinCode'];
        _isPinEnabled = data['isPinEnabled'] ?? false;
        _isAppLocked = data['isAppLocked'] ?? false;

        // Tự động khóa app khi khởi động nếu PIN được bật
        // CHỈ chạy một lần duy nhất khi provider được khởi tạo
        if (!_isInitialized &&
            _isPinEnabled &&
            _pinCode != null &&
            !_isAppLocked) {
          print('SettingsProvider: Auto-locking app on startup (local only)');
          _isAppLocked = true;
          _hasAutoLocked = true; // Đánh dấu đã auto-lock
          _isInitialized = true; // Đánh dấu đã khởi tạo
          // KHÔNG gọi updateSettings để tránh vòng lặp
        } else if (!_isPinEnabled) {
          print('SettingsProvider: PIN is disabled, not auto-locking');
          _isAppLocked = false; // Đảm bảo không bị khóa khi PIN tắt
          _hasAutoLocked = false; // Reset flag
        }

        // Đánh dấu đã khởi tạo sau lần đầu tiên load data
        if (!_isInitialized) {
          _isInitialized = true;
        }
      }
      _loading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      if (_isDisposed) {
        print('SettingsProvider: Ignoring error - provider disposed');
        return;
      }
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

  Future<void> setPhoneNumber(String phoneNumber) async {
    _phoneNumber = phoneNumber;
    await updateSettings({'phoneNumber': _phoneNumber});
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

  // Add missing getAlertStatus method
  AlertStatus getAlertStatus(double currentAmount, double limit) {
    if (limit <= 0) return AlertStatus.none;

    final percentage = (currentAmount / limit) * 100;

    if (percentage >= 100) return AlertStatus.critical;
    if (percentage >= 80) return AlertStatus.warning;
    if (percentage >= 60) return AlertStatus.caution;
    if (percentage >= 40) return AlertStatus.normal;
    return AlertStatus.none;
  }

  // PIN Security methods
  Future<void> setPinCode(String pin) async {
    _pinCode = pin;
    _isPinEnabled = true;
    await updateSettings({
      'pinCode': _pinCode,
      'isPinEnabled': _isPinEnabled,
    });
    notifyListeners();
  }

  Future<void> disablePinCode() async {
    print('SettingsProvider: disablePinCode called');
    print(
        'SettingsProvider: Before disable - isPinEnabled: $_isPinEnabled, pinCode: $_pinCode, isAppLocked: $_isAppLocked');

    _pinCode = null;
    _isPinEnabled = false;
    _isAppLocked = false;
    _hasAutoLocked = false; // Reset auto-lock flag

    print(
        'SettingsProvider: After disable - isPinEnabled: $_isPinEnabled, pinCode: $_pinCode, isAppLocked: $_isAppLocked');

    await updateSettings({
      'pinCode': null,
      'isPinEnabled': _isPinEnabled,
      'isAppLocked': _isAppLocked,
    });

    print('SettingsProvider: Firebase updated successfully');
    notifyListeners();
    print('SettingsProvider: PIN disabled successfully');
  }

  Future<void> changePinCode(String oldPin, String newPin) async {
    if (_pinCode == oldPin) {
      await setPinCode(newPin);
    } else {
      throw Exception('Mã PIN cũ không đúng');
    }
  }

  bool verifyPinCode(String inputPin) {
    print(
        'SettingsProvider: verifyPinCode - inputPin: $inputPin, storedPin: $_pinCode');
    bool result = _pinCode == inputPin;
    print('SettingsProvider: verifyPinCode result: $result');
    return result;
  }

  Future<void> lockApp() async {
    print('SettingsProvider: lockApp called');
    if (_isPinEnabled) {
      _isAppLocked = true;
      await updateSettings({'isAppLocked': _isAppLocked});
      notifyListeners();
      print('SettingsProvider: App locked successfully');
    }
  }

  Future<void> unlockApp() async {
    print('SettingsProvider: unlockApp called');
    _isAppLocked = false;
    _hasAutoLocked = false; // Reset flag khi unlock
    _isInitialized = true; // Đảm bảo đã khởi tạo
    await updateSettings({'isAppLocked': _isAppLocked});
    notifyListeners();
    print('SettingsProvider: App unlocked successfully');
  }

  Future<void> unlockAppWithPin(String pin) async {
    if (verifyPinCode(pin)) {
      await unlockApp();
    } else {
      throw Exception('Mã PIN không đúng');
    }
  }

  bool shouldShowPinScreen() {
    print(
        'SettingsProvider: shouldShowPinScreen - isPinEnabled: $_isPinEnabled, isAppLocked: $_isAppLocked, pinCode: $_pinCode');
    // Chỉ yêu cầu nhập PIN khi PIN được bật VÀ app đang bị khóa
    // Không yêu cầu PIN khi app đã được unlock (isAppLocked = false)
    bool result = _isPinEnabled && _isAppLocked;
    print('SettingsProvider: shouldShowPinScreen result: $result');
    return result;
  }
}
