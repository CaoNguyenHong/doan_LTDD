import 'package:flutter/foundation.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:spend_sage/providers/expense_provider.dart';

class AnalyticsProvider with ChangeNotifier {
  final ExpenseProvider _expenseProvider;
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String _error = '';

  AnalyticsProvider(this._expenseProvider) {
    _initializeRealtimeAnalytics();
  }

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String get error => _error;

  /// Initialize realtime analytics
  void _initializeRealtimeAnalytics() {
    print('📊 AnalyticsProvider: Initializing realtime analytics...');
    _setLoading(true);

    // Listen to expense changes
    _expenseProvider.addListener(_onExpensesChanged);
    _onExpensesChanged(); // Initial load
  }

  /// Handle expense changes
  void _onExpensesChanged() {
    print('📊 AnalyticsProvider: Expenses changed, updating analytics...');
    _expenses = _expenseProvider.expenses;
    _error = _expenseProvider.error;
    _setLoading(_expenseProvider.isLoading);
    notifyListeners();
  }

  /// Get realtime spending summary
  Map<String, dynamic> getSpendingSummary() {
    if (_expenses.isEmpty) {
      return {
        'totalSpending': 0.0,
        'averageTransaction': 0.0,
        'transactionCount': 0,
        'highestSpending': 0.0,
        'lowestSpending': 0.0,
      };
    }

    final totalSpending =
        _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final averageTransaction = totalSpending / _expenses.length;
    final amounts = _expenses.map((e) => e.amount).toList();
    final highestSpending = amounts.reduce((a, b) => a > b ? a : b);
    final lowestSpending = amounts.reduce((a, b) => a < b ? a : b);

    return {
      'totalSpending': totalSpending,
      'averageTransaction': averageTransaction,
      'transactionCount': _expenses.length,
      'highestSpending': highestSpending,
      'lowestSpending': lowestSpending,
    };
  }

  /// Get realtime category breakdown
  Map<String, double> getCategoryBreakdown() {
    final Map<String, double> breakdown = {};

    for (var expense in _expenses) {
      breakdown[expense.category] =
          (breakdown[expense.category] ?? 0.0) + expense.amount;
    }

    return breakdown;
  }

  /// Get realtime daily spending for last 7 days
  List<double> getDailySpending() {
    final now = DateTime.now();
    final dailySpending = <double>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayExpenses = _expenses.where((expense) {
        return expense.dateTime.year == date.year &&
            expense.dateTime.month == date.month &&
            expense.dateTime.day == date.day;
      });

      final dayTotal =
          dayExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      dailySpending.add(dayTotal);
    }

    return dailySpending;
  }

  /// Get realtime spending trends
  Map<String, dynamic> getSpendingTrends() {
    if (_expenses.length < 2) {
      return {
        'trend': 'stable',
        'change': 0.0,
        'direction': 'none',
      };
    }

    final sortedExpenses = List<Expense>.from(_expenses)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final firstHalf = sortedExpenses.take(_expenses.length ~/ 2);
    final secondHalf = sortedExpenses.skip(_expenses.length ~/ 2);

    final firstTotal =
        firstHalf.fold(0.0, (sum, expense) => sum + expense.amount);
    final secondTotal =
        secondHalf.fold(0.0, (sum, expense) => sum + expense.amount);

    final change = secondTotal - firstTotal;
    final percentageChange = firstTotal > 0 ? (change / firstTotal * 100) : 0;

    String direction = 'stable';
    if (percentageChange > 5)
      direction = 'increasing';
    else if (percentageChange < -5) direction = 'decreasing';

    return {
      'trend': direction,
      'change': change,
      'percentageChange': percentageChange,
      'direction': direction,
    };
  }

  /// Get realtime insights
  List<String> getInsights() {
    final insights = <String>[];
    final summary = getSpendingSummary();
    final trends = getSpendingTrends();

    if (summary['transactionCount'] == 0) {
      insights.add('Chưa có chi tiêu nào được ghi nhận.');
      return insights;
    }

    // Spending trend insight
    if (trends['direction'] == 'increasing') {
      insights.add('Chi tiêu đang tăng so với trước đây.');
    } else if (trends['direction'] == 'decreasing') {
      insights.add('Chi tiêu đang giảm so với trước đây.');
    } else {
      insights.add('Chi tiêu ổn định.');
    }

    // Category insight
    final categoryBreakdown = getCategoryBreakdown();
    if (categoryBreakdown.isNotEmpty) {
      final topCategory =
          categoryBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add(
          'Danh mục chi tiêu nhiều nhất: ${_getCategoryDisplayName(topCategory.key)}');
    }

    // Amount insight
    if (summary['highestSpending'] > 0) {
      insights.add(
          'Giao dịch cao nhất: ${summary['highestSpending'].toStringAsFixed(2)}');
    }

    return insights;
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return 'Ăn uống';
      case 'transport':
        return 'Giao thông';
      case 'utilities':
        return 'Tiện ích';
      case 'health':
        return 'Sức khỏe';
      case 'education':
        return 'Giáo dục';
      case 'shopping':
        return 'Mua sắm';
      case 'entertainment':
        return 'Giải trí';
      default:
        return 'Khác';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _expenseProvider.removeListener(_onExpensesChanged);
    super.dispose();
  }
}
