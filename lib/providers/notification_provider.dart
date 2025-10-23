import 'package:flutter/foundation.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:spend_sage/providers/expense_provider.dart';
import 'package:spend_sage/providers/settings_provider.dart';

class NotificationProvider with ChangeNotifier {
  final ExpenseProvider _expenseProvider;
  final SettingsProvider _settingsProvider;

  List<String> _notifications = [];
  bool _hasNewNotifications = false;

  NotificationProvider(this._expenseProvider, this._settingsProvider) {
    _initializeRealtimeNotifications();
  }

  List<String> get notifications => _notifications;
  bool get hasNewNotifications => _hasNewNotifications;

  /// Initialize realtime notifications
  void _initializeRealtimeNotifications() {
    print('🔔 NotificationProvider: Initializing realtime notifications...');

    // Listen to expense changes
    _expenseProvider.addListener(_onExpensesChanged);
    _onExpensesChanged(); // Initial check
  }

  /// Handle expense changes
  void _onExpensesChanged() {
    _checkSpendingLimits();
    _checkSpendingTrends();
    _checkCategoryInsights();
  }

  /// Check spending limits
  void _checkSpendingLimits() {
    final expenses = _expenseProvider.expenses;
    final settings = _settingsProvider;

    if (expenses.isEmpty) return;

    // Check daily limit
    final today = DateTime.now();
    final todayExpenses = expenses.where((expense) {
      return expense.dateTime.year == today.year &&
          expense.dateTime.month == today.month &&
          expense.dateTime.day == today.day;
    });

    final todayTotal =
        todayExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

    if (settings.dailyLimit > 0) {
      final percentage = (todayTotal / settings.dailyLimit * 100);

      if (percentage >= 100) {
        _addNotification('⚠️ Bạn đã vượt quá giới hạn chi tiêu hàng ngày!');
      } else if (percentage >= 80) {
        _addNotification(
            '⚠️ Bạn đã sử dụng ${percentage.toStringAsFixed(0)}% giới hạn chi tiêu hàng ngày.');
      }
    }

    // Check weekly limit
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekExpenses = expenses.where((expense) {
      return expense.dateTime.isAfter(weekStart) &&
          expense.dateTime.isBefore(today.add(Duration(days: 1)));
    });

    final weekTotal =
        weekExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

    if (settings.weeklyLimit > 0) {
      final percentage = (weekTotal / settings.weeklyLimit * 100);

      if (percentage >= 100) {
        _addNotification('⚠️ Bạn đã vượt quá giới hạn chi tiêu hàng tuần!');
      } else if (percentage >= 80) {
        _addNotification(
            '⚠️ Bạn đã sử dụng ${percentage.toStringAsFixed(0)}% giới hạn chi tiêu hàng tuần.');
      }
    }

    // Check monthly limit
    final monthStart = DateTime(today.year, today.month, 1);
    final monthExpenses = expenses.where((expense) {
      return expense.dateTime.isAfter(monthStart) &&
          expense.dateTime.isBefore(today.add(Duration(days: 1)));
    });

    final monthTotal =
        monthExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

    if (settings.monthlyLimit > 0) {
      final percentage = (monthTotal / settings.monthlyLimit * 100);

      if (percentage >= 100) {
        _addNotification('⚠️ Bạn đã vượt quá giới hạn chi tiêu hàng tháng!');
      } else if (percentage >= 80) {
        _addNotification(
            '⚠️ Bạn đã sử dụng ${percentage.toStringAsFixed(0)}% giới hạn chi tiêu hàng tháng.');
      }
    }
  }

  /// Check spending trends
  void _checkSpendingTrends() {
    final expenses = _expenseProvider.expenses;
    if (expenses.length < 2) return;

    // Check if spending is increasing rapidly
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final firstHalf = sortedExpenses.take(expenses.length ~/ 2);
    final secondHalf = sortedExpenses.skip(expenses.length ~/ 2);

    final firstTotal =
        firstHalf.fold(0.0, (sum, expense) => sum + expense.amount);
    final secondTotal =
        secondHalf.fold(0.0, (sum, expense) => sum + expense.amount);

    if (firstTotal > 0) {
      final increase = ((secondTotal - firstTotal) / firstTotal * 100);

      if (increase > 50) {
        _addNotification(
            '📈 Chi tiêu đã tăng ${increase.toStringAsFixed(0)}% so với trước đây.');
      } else if (increase < -30) {
        _addNotification(
            '📉 Chi tiêu đã giảm ${(-increase).toStringAsFixed(0)}% so với trước đây.');
      }
    }
  }

  /// Check category insights
  void _checkCategoryInsights() {
    final expenses = _expenseProvider.expenses;
    if (expenses.isEmpty) return;

    // Check category distribution
    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }

    if (categoryTotals.isNotEmpty) {
      final totalSpending =
          categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
      final topCategory =
          categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);

      final percentage = (topCategory.value / totalSpending * 100);

      if (percentage > 50) {
        _addNotification(
            '🎯 Bạn chi tiêu ${percentage.toStringAsFixed(0)}% cho ${_getCategoryDisplayName(topCategory.key)}.');
      }
    }
  }

  /// Add notification
  void _addNotification(String message) {
    if (!_notifications.contains(message)) {
      _notifications.insert(0, message);
      _hasNewNotifications = true;

      // Keep only last 10 notifications
      if (_notifications.length > 10) {
        _notifications = _notifications.take(10).toList();
      }

      notifyListeners();
    }
  }

  /// Mark notifications as read
  void markAsRead() {
    _hasNewNotifications = false;
    notifyListeners();
  }

  /// Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    _hasNewNotifications = false;
    notifyListeners();
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

  @override
  void dispose() {
    _expenseProvider.removeListener(_onExpensesChanged);
    super.dispose();
  }
}
