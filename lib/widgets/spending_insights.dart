import 'package:flutter/material.dart';
import 'package:spend_sage/hive/expense.dart';

class SpendingInsights extends StatefulWidget {
  final List<Expense> expenses;

  const SpendingInsights({super.key, required this.expenses});

  @override
  State<SpendingInsights> createState() => _SpendingInsightsState();
}

class _SpendingInsightsState extends State<SpendingInsights>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insights = _calculateInsights();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Color(0xFF667eea),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin chi tiêu thông minh',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D3748),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phân tích hành vi chi tiêu của bạn',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Insights Grid
            SizedBox(
              height: 400,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildInsightCard(
                        'Chi tiêu hôm nay',
                        '\$${insights.todaySpending.toStringAsFixed(2)}',
                        Icons.today,
                        const Color(0xFF667eea),
                        insights.todayVsYesterday,
                      ),
                      _buildInsightCard(
                        'Chi tiêu tuần này',
                        '\$${insights.weekSpending.toStringAsFixed(2)}',
                        Icons.date_range,
                        const Color(0xFF48BB78),
                        insights.weekVsLastWeek,
                      ),
                      _buildInsightCard(
                        'Chi tiêu tháng này',
                        '\$${insights.monthSpending.toStringAsFixed(2)}',
                        Icons.calendar_month,
                        const Color(0xFFED8936),
                        insights.monthVsLastMonth,
                      ),
                      _buildInsightCard(
                        'Trung bình/ngày',
                        '\$${insights.dailyAverage.toStringAsFixed(2)}',
                        Icons.trending_up,
                        const Color(0xFF9F7AEA),
                        insights.dailyAverageTrend,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Spending Patterns
            const SizedBox(height: 20),
            _buildSpendingPatterns(insights),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(
      String title, String value, IconData icon, Color color, double trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      trend > 0 ? Colors.red.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend > 0 ? Icons.trending_up : Icons.trending_down,
                      color: trend > 0 ? Colors.red : Colors.green,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${(trend * 100).abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: trend > 0 ? Colors.red : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingPatterns(SpendingInsightsData insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.grey.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mẫu chi tiêu',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPatternItem(
            'Ngày chi tiêu nhiều nhất',
            insights.highestSpendingDay,
            '\$${insights.highestSpendingAmount.toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.red,
          ),
          _buildPatternItem(
            'Thời gian chi tiêu nhiều nhất',
            insights.mostSpendingHour.toString(),
            'Giờ ${insights.mostSpendingHour}',
            Icons.access_time,
            Colors.blue,
          ),
          _buildPatternItem(
            'Danh mục chi tiêu nhiều nhất',
            insights.topCategory,
            '${(insights.topCategoryPercentage * 100).toStringAsFixed(1)}%',
            Icons.category,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(
      String label, String value, String amount, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SpendingInsightsData _calculateInsights() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    // Today's spending
    final todaySpending = widget.expenses
        .where((expense) => expense.dateTime.isAfter(today))
        .fold(0.0, (sum, expense) => sum + expense.amount);

    // Yesterday's spending
    final yesterdaySpending = widget.expenses
        .where((expense) =>
            expense.dateTime.isAfter(yesterday) &&
            expense.dateTime.isBefore(today))
        .fold(0.0, (sum, expense) => sum + expense.amount);

    // This week's spending
    final weekSpending = widget.expenses
        .where((expense) => expense.dateTime.isAfter(weekStart))
        .fold(0.0, (sum, expense) => sum + expense.amount);

    // Last week's spending
    final lastWeekSpending = widget.expenses
        .where((expense) =>
            expense.dateTime.isAfter(lastWeekStart) &&
            expense.dateTime.isBefore(weekStart))
        .fold(0.0, (sum, expense) => sum + expense.amount);

    // This month's spending
    final monthSpending = widget.expenses
        .where((expense) => expense.dateTime.isAfter(monthStart))
        .fold(0.0, (sum, expense) => sum + expense.amount);

    // Last month's spending
    final lastMonthSpending = widget.expenses
        .where((expense) =>
            expense.dateTime.isAfter(lastMonthStart) &&
            expense.dateTime.isBefore(monthStart))
        .fold(0.0, (sum, expense) => sum + expense.amount);

    // Calculate trends
    final todayVsYesterday = yesterdaySpending > 0
        ? (todaySpending - yesterdaySpending) / yesterdaySpending
        : 0.0;
    final weekVsLastWeek = lastWeekSpending > 0
        ? (weekSpending - lastWeekSpending) / lastWeekSpending
        : 0.0;
    final monthVsLastMonth = lastMonthSpending > 0
        ? (monthSpending - lastMonthSpending) / lastMonthSpending
        : 0.0;

    // Daily average
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyAverage = monthSpending / daysInMonth;
    final dailyAverageTrend = monthVsLastMonth; // Simplified

    // Find highest spending day
    final dailySpending = <DateTime, double>{};
    for (var expense in widget.expenses) {
      final day = DateTime(
          expense.dateTime.year, expense.dateTime.month, expense.dateTime.day);
      dailySpending[day] = (dailySpending[day] ?? 0) + expense.amount;
    }

    final highestSpendingDay = dailySpending.isNotEmpty
        ? dailySpending.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    // Find most spending hour
    final hourlySpending = <int, double>{};
    for (var expense in widget.expenses) {
      hourlySpending[expense.dateTime.hour] =
          (hourlySpending[expense.dateTime.hour] ?? 0) + expense.amount;
    }

    final mostSpendingHour = hourlySpending.isNotEmpty
        ? hourlySpending.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 12;

    // Find top category
    final categorySpending = <String, double>{};
    for (var expense in widget.expenses) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    final topCategory = categorySpending.isNotEmpty
        ? categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    final totalSpending =
        categorySpending.values.fold(0.0, (sum, amount) => sum + amount);
    final topCategoryPercentage = topCategory != null && totalSpending > 0
        ? topCategory.value / totalSpending
        : 0.0;

    return SpendingInsightsData(
      todaySpending: todaySpending,
      weekSpending: weekSpending,
      monthSpending: monthSpending,
      dailyAverage: dailyAverage,
      todayVsYesterday: todayVsYesterday,
      weekVsLastWeek: weekVsLastWeek,
      monthVsLastMonth: monthVsLastMonth,
      dailyAverageTrend: dailyAverageTrend,
      highestSpendingDay: highestSpendingDay?.key.day.toString() ?? 'N/A',
      highestSpendingAmount: highestSpendingDay?.value ?? 0.0,
      mostSpendingHour: mostSpendingHour,
      topCategory: _getCategoryDisplayName(topCategory?.key ?? ''),
      topCategoryPercentage: topCategoryPercentage,
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return 'Ăn uống';
      case 'transport':
        return 'Giao thông';
      case 'shopping':
        return 'Mua sắm';
      case 'utilities':
        return 'Tiện ích';
      case 'entertainment':
        return 'Giải trí';
      default:
        return 'Khác';
    }
  }
}

class SpendingInsightsData {
  final double todaySpending;
  final double weekSpending;
  final double monthSpending;
  final double dailyAverage;
  final double todayVsYesterday;
  final double weekVsLastWeek;
  final double monthVsLastMonth;
  final double dailyAverageTrend;
  final String highestSpendingDay;
  final double highestSpendingAmount;
  final int mostSpendingHour;
  final String topCategory;
  final double topCategoryPercentage;

  SpendingInsightsData({
    required this.todaySpending,
    required this.weekSpending,
    required this.monthSpending,
    required this.dailyAverage,
    required this.todayVsYesterday,
    required this.weekVsLastWeek,
    required this.monthVsLastMonth,
    required this.dailyAverageTrend,
    required this.highestSpendingDay,
    required this.highestSpendingAmount,
    required this.mostSpendingHour,
    required this.topCategory,
    required this.topCategoryPercentage,
  });
}
