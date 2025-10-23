import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';

  // Cache for exchange rates
  static Map<String, double> _exchangeRates = {};
  static DateTime? _lastUpdated;
  static const Duration _cacheExpiry = Duration(hours: 1);

  /// Get exchange rate from one currency to another
  static Future<double> getExchangeRate(
      String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return 1.0;

    // Check if we need to update cache
    if (_lastUpdated == null ||
        DateTime.now().difference(_lastUpdated!) > _cacheExpiry) {
      await _updateExchangeRates(fromCurrency);
    }

    return _exchangeRates[toCurrency] ?? 1.0;
  }

  /// Update exchange rates from API
  static Future<void> _updateExchangeRates(String baseCurrency) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$baseCurrency'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _exchangeRates = Map<String, double>.from(data['rates']);
        _lastUpdated = DateTime.now();
        print('💱 CurrencyService: Updated exchange rates for $baseCurrency');
      } else {
        print(
            '💱 CurrencyService: Failed to fetch exchange rates: ${response.statusCode}');
        _setDefaultRates();
      }
    } catch (e) {
      print('💱 CurrencyService: Error fetching exchange rates: $e');
      _setDefaultRates();
    }
  }

  /// Set default exchange rates (fallback)
  static void _setDefaultRates() {
    _exchangeRates = {
      'USD': 1.0,
      'VND': 24000.0,
      'EUR': 0.85,
      'GBP': 0.73,
      'JPY': 110.0,
      'KRW': 1200.0,
      'CNY': 6.5,
      'SGD': 1.35,
      'THB': 33.0,
      'IDR': 14000.0,
    };
    _lastUpdated = DateTime.now();
  }

  /// Convert amount from one currency to another
  static Future<double> convertAmount(
      double amount, String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return amount;

    final rate = await getExchangeRate(fromCurrency, toCurrency);
    return amount * rate;
  }

  /// Get currency symbol
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'VND':
        return '₫';
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
      case 'SGD':
        return 'S\$';
      case 'THB':
        return '฿';
      case 'IDR':
        return 'Rp';
      default:
        return currencyCode;
    }
  }

  /// Get currency name
  static String getCurrencyName(String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return 'US Dollar';
      case 'VND':
        return 'Vietnamese Dong';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'British Pound';
      case 'JPY':
        return 'Japanese Yen';
      case 'KRW':
        return 'South Korean Won';
      case 'CNY':
        return 'Chinese Yuan';
      case 'SGD':
        return 'Singapore Dollar';
      case 'THB':
        return 'Thai Baht';
      case 'IDR':
        return 'Indonesian Rupiah';
      default:
        return currencyCode;
    }
  }
}
