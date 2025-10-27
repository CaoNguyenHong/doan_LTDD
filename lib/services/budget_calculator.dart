import '../models/budget.dart';
import '../models/transaction.dart';

class BudgetCalculator {
  /// Tính toán số tiền đã chi cho một budget dựa trên transactions
  static double calculateSpentForBudget(
      Budget budget, List<Transaction> transactions) {
    final now = DateTime.now();
    final budgetStartDate = _getBudgetStartDate(budget, now);
    final budgetEndDate = _getBudgetEndDate(budget, now);

    // Lọc transactions trong khoảng thời gian của budget
    final relevantTransactions = transactions.where((transaction) {
      if (transaction.type != 'expense') return false;
      if (transaction.dateTime.isBefore(budgetStartDate)) return false;
      if (transaction.dateTime.isAfter(budgetEndDate)) return false;

      // Nếu budget có categoryId cụ thể, chỉ tính transactions của category đó
      if (budget.categoryId != null &&
          transaction.categoryId != budget.categoryId) {
        return false;
      }

      return true;
    }).toList();

    // Tính tổng số tiền đã chi
    return relevantTransactions.fold(
        0.0, (sum, transaction) => sum + transaction.amount);
  }

  /// Cập nhật spent cho tất cả budgets dựa trên transactions
  static List<Budget> updateBudgetsWithSpent(
      List<Budget> budgets, List<Transaction> transactions) {
    return budgets.map((budget) {
      final spent = calculateSpentForBudget(budget, transactions);
      return budget.copyWith(spent: spent);
    }).toList();
  }

  /// Lấy ngày bắt đầu của budget period
  static DateTime _getBudgetStartDate(Budget budget, DateTime now) {
    switch (budget.period) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
      case 'weekly':
        // Tuần bắt đầu từ thứ 2
        final weekday = now.weekday;
        final daysFromMonday = weekday - 1;
        return DateTime(now.year, now.month, now.day - daysFromMonday);
      case 'monthly':
        return DateTime(now.year, now.month, 1);
      case 'yearly':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  /// Lấy ngày kết thúc của budget period
  static DateTime _getBudgetEndDate(Budget budget, DateTime now) {
    switch (budget.period) {
      case 'daily':
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case 'weekly':
        final weekday = now.weekday;
        final daysFromMonday = weekday - 1;
        final weekStart =
            DateTime(now.year, now.month, now.day - daysFromMonday);
        return weekStart
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      case 'monthly':
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        return nextMonth.subtract(const Duration(seconds: 1));
      case 'yearly':
        return DateTime(now.year, 12, 31, 23, 59, 59);
      default:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  /// Kiểm tra xem budget có vượt quá giới hạn không
  static bool isOverBudget(Budget budget) {
    return budget.spent > budget.limit;
  }

  /// Kiểm tra xem budget có gần đạt giới hạn không (>= 80%)
  static bool isNearLimit(Budget budget) {
    return budget.percentage >= 80 && budget.percentage < 100;
  }

  /// Kiểm tra xem budget có cảnh báo không (>= 100%)
  static bool isWarning(Budget budget) {
    return budget.percentage >= 100;
  }
}
