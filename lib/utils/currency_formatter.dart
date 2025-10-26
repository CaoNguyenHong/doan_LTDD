import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String currency = 'VND'}) {
    // Format number with thousand separators (dots)
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount.toInt())} $currency';
  }

  static String formatCompact(double amount, {String currency = 'VND'}) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M $currency';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K $currency';
    } else {
      return format(amount, currency: currency);
    }
  }
}
