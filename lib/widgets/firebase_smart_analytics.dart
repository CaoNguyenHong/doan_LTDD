import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart' as models;
import '../utils/currency_formatter.dart';

class FirebaseSmartAnalytics extends StatefulWidget {
  final List<models.Transaction> transactions;
  final String selectedPeriod;
  final String selectedTransactionType;

  const FirebaseSmartAnalytics({
    super.key,
    required this.transactions,
    required this.selectedPeriod,
    required this.selectedTransactionType,
  });

  @override
  State<FirebaseSmartAnalytics> createState() => _FirebaseSmartAnalyticsState();
}

class _FirebaseSmartAnalyticsState extends State<FirebaseSmartAnalytics>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

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
        final filteredTransactions =
            _filterTransactionsByType(widget.transactions);
        final analytics = _calculateSmartAnalytics(filteredTransactions);
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
                            'Phân tích chi tiêu',
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
                    // Removed dropdowns - using filters from parent screen
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

  // Removed dropdown selectors - using parent screen filters

  Widget _buildKeyMetrics(FirebaseAnalyticsData analytics, String currency) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Tổng ${_getTransactionTypeDisplayName()}',
            '${CurrencyFormatter.format(analytics.totalAmount, currency: currency)}',
            _getTransactionTypeIcon(),
            _getTransactionTypeColor(),
            analytics.trend,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Trung bình/ngày',
            '${CurrencyFormatter.format(analytics.dailyAverage, currency: currency)}',
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

  Widget _buildSpendingPatterns(
      FirebaseAnalyticsData analytics, String currency) {
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
                'Thói quen ${_getTransactionTypeDisplayName().toLowerCase()}',
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
            'Ngày ${_getTransactionTypeDisplayName().toLowerCase()} nhiều nhất',
            'Thứ ${analytics.highestSpendingDay}',
            '${CurrencyFormatter.format(analytics.highestSpendingAmount, currency: currency)}',
            Icons.calendar_today,
            _getTransactionTypeColor(),
          ),
          _buildPatternRow(
            'Giờ ${_getTransactionTypeDisplayName().toLowerCase()} nhiều nhất',
            '${analytics.mostSpendingHour}:00',
            '${analytics.mostSpendingHourCount} giao dịch',
            Icons.access_time,
            Colors.blue,
          ),
          if (analytics.topCategory != null) ...[
            _buildPatternRow(
              'Danh mục ${_getTransactionTypeDisplayName().toLowerCase()} nhiều nhất',
              _getCategoryDisplayName(analytics.topCategory!),
              '${analytics.topCategoryPercentage.toStringAsFixed(1)}%',
              Icons.category,
              Colors.purple,
            ),
          ],
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

  Widget _buildRecommendations(
      FirebaseAnalyticsData analytics, String currency) {
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
                'Gợi ý tối ưu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.selectedTransactionType == 'expense') ...[
            _buildRecommendationRow(
              'Giảm chi tiêu danh mục ${analytics.topCategory != null ? _getCategoryDisplayName(analytics.topCategory!) : "chính"}',
              'Tiết kiệm ${analytics.potentialSavings.toStringAsFixed(0)}%',
              Icons.trending_down,
              Colors.green,
            ),
            _buildRecommendationRow(
              'Đặt mục tiêu ${_getTransactionTypeDisplayName().toLowerCase()} hàng ngày',
              '${CurrencyFormatter.format(analytics.recommendedDailyLimit, currency: currency)}/ngày',
              Icons.flag,
              Colors.blue,
            ),
          ] else ...[
            _buildRecommendationRow(
              'Tăng cường ${_getTransactionTypeDisplayName().toLowerCase()}',
              'Mục tiêu ${CurrencyFormatter.format(analytics.recommendedDailyLimit, currency: currency)}/ngày',
              Icons.trending_up,
              Colors.green,
            ),
            _buildRecommendationRow(
              'Theo dõi xu hướng ${_getTransactionTypeDisplayName().toLowerCase()}',
              'Duy trì mức ${analytics.trend}',
              Icons.track_changes,
              Colors.blue,
            ),
          ],
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

  List<models.Transaction> _filterTransactionsByType(
      List<models.Transaction> transactions) {
    return transactions
        .where((t) => t.type == widget.selectedTransactionType)
        .toList();
  }

  FirebaseAnalyticsData _calculateSmartAnalytics(
      List<models.Transaction> transactions) {
    if (transactions.isEmpty) {
      return FirebaseAnalyticsData.empty();
    }

    // Calculate total amount
    final totalAmount =
        transactions.fold(0.0, (sum, transaction) => sum + transaction.amount);

    // Calculate daily average
    final days = _getDaysInPeriod();
    final dailyAverage = totalAmount / days;

    // Calculate trends
    final trend = _calculateTrend(transactions);
    final dailyTrend = _calculateDailyTrend(transactions);

    // Find highest spending day
    final dailySpending = <int, double>{};
    for (var transaction in transactions) {
      final day = transaction.dateTime.weekday;
      dailySpending[day] = (dailySpending[day] ?? 0) + transaction.amount;
    }
    final highestSpendingDayEntry = dailySpending.isNotEmpty
        ? dailySpending.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    // Find most spending hour
    final hourlySpending = <int, int>{};
    for (var transaction in transactions) {
      final hour = transaction.dateTime.hour;
      hourlySpending[hour] = (hourlySpending[hour] ?? 0) + 1;
    }
    final mostSpendingHourEntry = hourlySpending.isNotEmpty
        ? hourlySpending.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    // Find top category (only for expenses)
    String? topCategory;
    double topCategoryPercentage = 0.0;
    if (widget.selectedTransactionType == 'expense') {
      final categorySpending = <String, double>{};
      for (var transaction in transactions) {
        final category = transaction.categoryId ?? 'other';
        categorySpending[category] =
            (categorySpending[category] ?? 0) + transaction.amount;
      }
      final topCategoryEntry = categorySpending.isNotEmpty
          ? categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b)
          : null;

      topCategory = topCategoryEntry?.key;
      topCategoryPercentage = topCategoryEntry != null && totalAmount > 0
          ? (topCategoryEntry.value / totalAmount * 100)
          : 0.0;
    }

    // Calculate recommendations
    final potentialSavings = topCategoryPercentage * 0.2; // 20% of top category
    final recommendedDailyLimit = dailyAverage *
        (widget.selectedTransactionType == 'expense' ? 0.8 : 1.2);

    return FirebaseAnalyticsData(
      totalAmount: totalAmount,
      dailyAverage: dailyAverage,
      trend: trend,
      dailyTrend: dailyTrend,
      highestSpendingDay: highestSpendingDayEntry?.key ?? 1,
      highestSpendingAmount: highestSpendingDayEntry?.value ?? 0.0,
      mostSpendingHour: mostSpendingHourEntry?.key ?? 12,
      mostSpendingHourCount: mostSpendingHourEntry?.value ?? 0,
      topCategory: topCategory,
      topCategoryPercentage: topCategoryPercentage,
      potentialSavings: potentialSavings,
      recommendedDailyLimit: recommendedDailyLimit,
    );
  }

  int _getDaysInPeriod() {
    switch (widget.selectedPeriod) {
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

  String _calculateTrend(List<models.Transaction> transactions) {
    if (transactions.length < 2) return 'Dữ liệu chưa đủ';

    final sortedTransactions = List<models.Transaction>.from(transactions)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final firstHalf = sortedTransactions
        .take(sortedTransactions.length ~/ 2)
        .fold(0.0, (sum, t) => sum + t.amount);
    final secondHalf = sortedTransactions
        .skip(sortedTransactions.length ~/ 2)
        .fold(0.0, (sum, t) => sum + t.amount);

    if (secondHalf > firstHalf * 1.1) return 'Tăng mạnh';
    if (secondHalf > firstHalf * 1.05) return 'Tăng nhẹ';
    if (secondHalf < firstHalf * 0.9) return 'Giảm mạnh';
    if (secondHalf < firstHalf * 0.95) return 'Giảm nhẹ';
    return 'Ổn định';
  }

  String _calculateDailyTrend(List<models.Transaction> transactions) {
    if (transactions.length < 7) return 'Dữ liệu chưa đủ';

    final dailyTotals = <DateTime, double>{};
    for (var transaction in transactions) {
      final day = DateTime(transaction.dateTime.year,
          transaction.dateTime.month, transaction.dateTime.day);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + transaction.amount;
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

  String _getTransactionTypeDisplayName() {
    switch (widget.selectedTransactionType) {
      case 'expense':
        return 'Chi tiêu';
      case 'income':
        return 'Thu nhập';
      case 'transfer':
        return 'Chuyển khoản';
      case 'refund':
        return 'Hoàn tiền';
      default:
        return 'Giao dịch';
    }
  }

  IconData _getTransactionTypeIcon() {
    switch (widget.selectedTransactionType) {
      case 'expense':
        return Icons.trending_down;
      case 'income':
        return Icons.trending_up;
      case 'transfer':
        return Icons.swap_horiz;
      case 'refund':
        return Icons.reply;
      default:
        return Icons.attach_money;
    }
  }

  Color _getTransactionTypeColor() {
    switch (widget.selectedTransactionType) {
      case 'expense':
        return Colors.red;
      case 'income':
        return Colors.green;
      case 'transfer':
        return Colors.blue;
      case 'refund':
        return Colors.orange;
      default:
        return const Color(0xFF667eea);
    }
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

class FirebaseAnalyticsData {
  final double totalAmount;
  final double dailyAverage;
  final String trend;
  final String dailyTrend;
  final int highestSpendingDay;
  final double highestSpendingAmount;
  final int mostSpendingHour;
  final int mostSpendingHourCount;
  final String? topCategory;
  final double topCategoryPercentage;
  final double potentialSavings;
  final double recommendedDailyLimit;

  FirebaseAnalyticsData({
    required this.totalAmount,
    required this.dailyAverage,
    required this.trend,
    required this.dailyTrend,
    required this.highestSpendingDay,
    required this.highestSpendingAmount,
    required this.mostSpendingHour,
    required this.mostSpendingHourCount,
    this.topCategory,
    required this.topCategoryPercentage,
    required this.potentialSavings,
    required this.recommendedDailyLimit,
  });

  factory FirebaseAnalyticsData.empty() {
    return FirebaseAnalyticsData(
      totalAmount: 0.0,
      dailyAverage: 0.0,
      trend: 'Dữ liệu chưa đủ',
      dailyTrend: 'Dữ liệu chưa đủ',
      highestSpendingDay: 1,
      highestSpendingAmount: 0.0,
      mostSpendingHour: 12,
      mostSpendingHourCount: 0,
      topCategory: null,
      topCategoryPercentage: 0.0,
      potentialSavings: 0.0,
      recommendedDailyLimit: 0.0,
    );
  }
}
