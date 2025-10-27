import 'package:flutter/material.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SmartAnalytics extends StatefulWidget {
  final List<Expense> expenses;

  const SmartAnalytics({super.key, required this.expenses});

  @override
  State<SmartAnalytics> createState() => _SmartAnalyticsState();
}

class _SmartAnalyticsState extends State<SmartAnalytics>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final analytics = _calculateSmartAnalytics();
        final currency = settings.currency;

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phân tích thông minh',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D3748),
                                ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                    _buildPeriodSelector(),
                  ],
                ),
                const SizedBox(height: 24),

                // Key Metrics
                _buildKeyMetrics(analytics, currency),
                const SizedBox(height: 24),

                // Spending Patterns
                _buildSpendingPatterns(analytics, currency),
                const SizedBox(height: 24),

                // Recommendations
                _buildRecommendations(analytics, currency),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF667eea).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          isDense: true,
          style: TextStyle(
            color: const Color(0xFF667eea),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          items: const [
            DropdownMenuItem(
              value: 'week',
              child: Text('Tuần'),
            ),
            DropdownMenuItem(
              value: 'month',
              child: Text('Tháng'),
            ),
            DropdownMenuItem(
              value: 'year',
              child: Text('Năm'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(SmartAnalyticsData analytics, String currency) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Tổng chi tiêu',
            '$currency${analytics.totalSpending.toStringAsFixed(2)}',
            Icons.attach_money,
            const Color(0xFF667eea),
            analytics.spendingTrend,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Trung bình/ngày',
            '$currency${analytics.dailyAverage.toStringAsFixed(2)}',
            Icons.trending_up,
            const Color(0xFFED8936),
            analytics.dailyTrend,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, String trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingPatterns(SmartAnalyticsData analytics, String currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: const Color(0xFF667eea),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Thói quen chi tiêu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPatternRow(
            'Ngày chi tiêu nhiều nhất',
            'Thứ ${analytics.highestSpendingDay}',
            '$currency${analytics.highestSpendingAmount.toStringAsFixed(2)}',
            Icons.calendar_today,
            Colors.red,
          ),
          _buildPatternRow(
            'Giờ chi tiêu nhiều nhất',
            '${analytics.mostSpendingHour}:00',
            '${analytics.mostSpendingHourCount} giao dịch',
            Icons.access_time,
            Colors.blue,
          ),
          _buildPatternRow(
            'Danh mục chi tiêu nhiều nhất',
            _getCategoryDisplayName(analytics.topCategory),
            '${analytics.topCategoryPercentage.toStringAsFixed(1)}%',
            Icons.category,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternRow(
      String label, String value, String amount, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(SmartAnalyticsData analytics, String currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Gợi ý tiết kiệm',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationRow(
            'Giảm chi tiêu danh mục ${_getCategoryDisplayName(analytics.topCategory)}',
            'Tiết kiệm ${analytics.potentialSavings.toStringAsFixed(0)}%',
            Icons.trending_down,
            Colors.green,
          ),
          _buildRecommendationRow(
            'Tăng cường theo dõi chi tiêu',
            'Đặt mục tiêu ${currency}${analytics.recommendedDailyLimit.toStringAsFixed(0)}/ngày',
            Icons.flag,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationRow(
      String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  SmartAnalyticsData _calculateSmartAnalytics() {
    final expenses = widget.expenses;
    if (expenses.isEmpty) {
      return SmartAnalyticsData.empty();
    }

    // Calculate total spending
    final totalSpending =
        expenses.fold(0.0, (sum, expense) => sum + expense.amount);

    // Calculate daily average
    final days = _getDaysInPeriod();
    final dailyAverage = totalSpending / days;

    // Calculate trends
    final spendingTrend = _calculateSpendingTrend(expenses);
    final dailyTrend = _calculateDailyTrend(expenses);

    // Find highest spending day
    final dailySpending = <int, double>{};
    for (var expense in expenses) {
      final day = expense.dateTime.weekday;
      dailySpending[day] = (dailySpending[day] ?? 0) + expense.amount;
    }
    final highestSpendingDayEntry = dailySpending.isNotEmpty
        ? dailySpending.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    // Find most spending hour
    final hourlySpending = <int, int>{};
    for (var expense in expenses) {
      final hour = expense.dateTime.hour;
      hourlySpending[hour] = (hourlySpending[hour] ?? 0) + 1;
    }
    final mostSpendingHourEntry = hourlySpending.isNotEmpty
        ? hourlySpending.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    // Find top category
    final categorySpending = <String, double>{};
    for (var expense in expenses) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }
    final topCategoryEntry = categorySpending.isNotEmpty
        ? categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    final topCategoryPercentage = topCategoryEntry != null && totalSpending > 0
        ? (topCategoryEntry.value / totalSpending * 100)
        : 0.0;

    // Calculate recommendations
    final potentialSavings = topCategoryPercentage * 0.2; // 20% of top category
    final recommendedDailyLimit = dailyAverage * 0.8; // 80% of current average

    return SmartAnalyticsData(
      totalSpending: totalSpending,
      dailyAverage: dailyAverage,
      spendingTrend: spendingTrend,
      dailyTrend: dailyTrend,
      highestSpendingDay: highestSpendingDayEntry?.key ?? 1,
      highestSpendingAmount: highestSpendingDayEntry?.value ?? 0.0,
      mostSpendingHour: mostSpendingHourEntry?.key ?? 12,
      mostSpendingHourCount: mostSpendingHourEntry?.value ?? 0,
      topCategory: topCategoryEntry?.key ?? 'other',
      topCategoryPercentage: topCategoryPercentage,
      potentialSavings: potentialSavings,
      recommendedDailyLimit: recommendedDailyLimit,
    );
  }

  int _getDaysInPeriod() {
    switch (_selectedPeriod) {
      case 'week':
        return 7;
      case 'month':
        return 30;
      case 'year':
        return 365;
      default:
        return 7;
    }
  }

  String _calculateSpendingTrend(List<Expense> expenses) {
    if (expenses.length < 2) return 'Dữ liệu chưa đủ';

    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final firstHalf = sortedExpenses
        .take(sortedExpenses.length ~/ 2)
        .fold(0.0, (sum, e) => sum + e.amount);
    final secondHalf = sortedExpenses
        .skip(sortedExpenses.length ~/ 2)
        .fold(0.0, (sum, e) => sum + e.amount);

    if (secondHalf > firstHalf * 1.1) return 'Tăng mạnh';
    if (secondHalf > firstHalf * 1.05) return 'Tăng nhẹ';
    if (secondHalf < firstHalf * 0.9) return 'Giảm mạnh';
    if (secondHalf < firstHalf * 0.95) return 'Giảm nhẹ';
    return 'Ổn định';
  }

  String _calculateDailyTrend(List<Expense> expenses) {
    if (expenses.length < 7) return 'Dữ liệu chưa đủ';

    final dailyTotals = <DateTime, double>{};
    for (var expense in expenses) {
      final day = DateTime(
          expense.dateTime.year, expense.dateTime.month, expense.dateTime.day);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
    }

    final sortedDays = dailyTotals.keys.toList()..sort();
    if (sortedDays.length < 2) return 'Dữ liệu chưa đủ';

    final recent = sortedDays.length >= 3
        ? sortedDays
            .skip(sortedDays.length - 3)
            .fold(0.0, (sum, day) => sum + dailyTotals[day]!)
        : sortedDays.fold(0.0, (sum, day) => sum + dailyTotals[day]!);
    final earlier = sortedDays.length >= 3
        ? sortedDays
            .take(sortedDays.length - 3)
            .fold(0.0, (sum, day) => sum + dailyTotals[day]!)
        : 0.0;

    if (recent > earlier * 1.1) return 'Tăng mạnh';
    if (recent > earlier * 1.05) return 'Tăng nhẹ';
    if (recent < earlier * 0.9) return 'Giảm mạnh';
    if (recent < earlier * 0.95) return 'Giảm nhẹ';
    return 'Ổn định';
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
}

class SmartAnalyticsData {
  final double totalSpending;
  final double dailyAverage;
  final String spendingTrend;
  final String dailyTrend;
  final int highestSpendingDay;
  final double highestSpendingAmount;
  final int mostSpendingHour;
  final int mostSpendingHourCount;
  final String topCategory;
  final double topCategoryPercentage;
  final double potentialSavings;
  final double recommendedDailyLimit;

  SmartAnalyticsData({
    required this.totalSpending,
    required this.dailyAverage,
    required this.spendingTrend,
    required this.dailyTrend,
    required this.highestSpendingDay,
    required this.highestSpendingAmount,
    required this.mostSpendingHour,
    required this.mostSpendingHourCount,
    required this.topCategory,
    required this.topCategoryPercentage,
    required this.potentialSavings,
    required this.recommendedDailyLimit,
  });

  factory SmartAnalyticsData.empty() {
    return SmartAnalyticsData(
      totalSpending: 0.0,
      dailyAverage: 0.0,
      spendingTrend: 'Dữ liệu chưa đủ',
      dailyTrend: 'Dữ liệu chưa đủ',
      highestSpendingDay: 1,
      highestSpendingAmount: 0.0,
      mostSpendingHour: 12,
      mostSpendingHourCount: 0,
      topCategory: 'other',
      topCategoryPercentage: 0.0,
      potentialSavings: 0.0,
      recommendedDailyLimit: 0.0,
    );
  }
}
