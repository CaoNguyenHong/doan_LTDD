import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class AdvancedAnalytics extends StatefulWidget {
  final List<Expense> expenses;

  const AdvancedAnalytics({super.key, required this.expenses});

  @override
  State<AdvancedAnalytics> createState() => _AdvancedAnalyticsState();
}

class _AdvancedAnalyticsState extends State<AdvancedAnalytics>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedMetric = 'spending';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
        final analytics = _calculateAnalytics();
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
                          Text(
                            'Hiểu rõ thói quen chi tiêu của bạn',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _buildMetricSelector(),
                  ],
                ),
                const SizedBox(height: 24),

                // Key Metrics
                _buildKeyMetrics(analytics, currency),
                const SizedBox(height: 24),

                // Trend Chart
                _buildTrendChart(analytics, currency),
                const SizedBox(height: 24),

                // Insights
                _buildInsights(analytics, currency),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricSelector() {
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
          value: _selectedMetric,
          isDense: true,
          style: TextStyle(
            color: const Color(0xFF667eea),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          items: const [
            DropdownMenuItem(
              value: 'spending',
              child: Text('Chi tiêu'),
            ),
            DropdownMenuItem(
              value: 'transactions',
              child: Text('Giao dịch'),
            ),
            DropdownMenuItem(
              value: 'categories',
              child: Text('Danh mục'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedMetric = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(AnalyticsData analytics, String currency) {
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
            'Trung bình',
            '$currency${analytics.averageTransaction.toStringAsFixed(2)}',
            Icons.trending_up,
            const Color(0xFFED8936),
            analytics.averageTrend,
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

  Widget _buildTrendChart(AnalyticsData analytics, String currency) {
    return Container(
      height: 200,
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
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateMaxY(analytics) / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < analytics.dailyData.length) {
                    return Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 20,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '$currency${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade200),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: analytics.dailyData
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: const Color(0xFF667eea),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF667eea).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsights(AnalyticsData analytics, String currency) {
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
                  Icons.lightbulb_outline,
                  color: const Color(0xFF667eea),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Thông tin chi tiết',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            'Chi tiêu cao nhất trong ngày',
            '$currency${analytics.highestDailySpending.toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.red,
          ),
          _buildInsightRow(
            'Chi tiêu thấp nhất trong ngày',
            '$currency${analytics.lowestDailySpending.toStringAsFixed(2)}',
            Icons.trending_down,
            Colors.green,
          ),
          _buildInsightRow(
            'Danh mục chi tiêu nhiều nhất',
            _getTopCategory(analytics),
            Icons.category,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  AnalyticsData _calculateAnalytics() {
    final now = DateTime.now();
    final expenses = widget.expenses;

    if (expenses.isEmpty) {
      return AnalyticsData(
        totalSpending: 0,
        averageTransaction: 0,
        highestDailySpending: 0,
        lowestDailySpending: 0,
        dailyData: [],
        spendingTrend: 'Không có dữ liệu',
        averageTrend: 'Không có dữ liệu',
      );
    }

    // Calculate total spending
    final totalSpending =
        expenses.fold(0.0, (sum, expense) => sum + expense.amount);

    // Calculate average transaction
    final averageTransaction = totalSpending / expenses.length;

    // Calculate daily spending for the last 7 days
    final dailyData = <double>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayExpenses = expenses.where((expense) {
        return expense.dateTime.year == date.year &&
            expense.dateTime.month == date.month &&
            expense.dateTime.day == date.day;
      });
      final dayTotal =
          dayExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      dailyData.add(dayTotal);
    }

    // Calculate highest and lowest daily spending
    final highestDailySpending = dailyData.reduce((a, b) => a > b ? a : b);
    final lowestDailySpending = dailyData.reduce((a, b) => a < b ? a : b);

    // Calculate trends
    final spendingTrend = _calculateSpendingTrend(dailyData);
    final averageTrend = _calculateAverageTrend(expenses);

    return AnalyticsData(
      totalSpending: totalSpending,
      averageTransaction: averageTransaction,
      highestDailySpending: highestDailySpending,
      lowestDailySpending: lowestDailySpending,
      dailyData: dailyData,
      spendingTrend: spendingTrend,
      averageTrend: averageTrend,
    );
  }

  String _calculateSpendingTrend(List<double> dailyData) {
    if (dailyData.length < 2) return 'Không đủ dữ liệu';

    final firstHalf =
        dailyData.take(3).fold(0.0, (sum, value) => sum + value) / 3;
    final secondHalf =
        dailyData.skip(4).fold(0.0, (sum, value) => sum + value) / 3;

    if (secondHalf > firstHalf * 1.1) return 'Tăng mạnh';
    if (secondHalf > firstHalf * 1.05) return 'Tăng nhẹ';
    if (secondHalf < firstHalf * 0.9) return 'Giảm mạnh';
    if (secondHalf < firstHalf * 0.95) return 'Giảm nhẹ';
    return 'Ổn định';
  }

  String _calculateAverageTrend(List<Expense> expenses) {
    if (expenses.length < 2) return 'Không đủ dữ liệu';

    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final firstHalf = sortedExpenses.take(expenses.length ~/ 2);
    final secondHalf = sortedExpenses.skip(expenses.length ~/ 2);

    final firstAvg =
        firstHalf.fold(0.0, (sum, expense) => sum + expense.amount) /
            firstHalf.length;
    final secondAvg =
        secondHalf.fold(0.0, (sum, expense) => sum + expense.amount) /
            secondHalf.length;

    if (secondAvg > firstAvg * 1.1) return 'Tăng mạnh';
    if (secondAvg > firstAvg * 1.05) return 'Tăng nhẹ';
    if (secondAvg < firstAvg * 0.9) return 'Giảm mạnh';
    if (secondAvg < firstAvg * 0.95) return 'Giảm nhẹ';
    return 'Ổn định';
  }

  String _getTopCategory(AnalyticsData analytics) {
    final categoryTotals = <String, double>{};
    for (var expense in widget.expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    if (categoryTotals.isEmpty) return 'Không có dữ liệu';

    final topCategory =
        categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);

    return _getCategoryDisplayName(topCategory.key);
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

  double _calculateMaxY(AnalyticsData analytics) {
    if (analytics.dailyData.isEmpty) return 100;
    final max = analytics.dailyData.reduce((a, b) => a > b ? a : b);
    return (max * 1.2).ceilToDouble();
  }
}

class AnalyticsData {
  final double totalSpending;
  final double averageTransaction;
  final double highestDailySpending;
  final double lowestDailySpending;
  final List<double> dailyData;
  final String spendingTrend;
  final String averageTrend;

  AnalyticsData({
    required this.totalSpending,
    required this.averageTransaction,
    required this.highestDailySpending,
    required this.lowestDailySpending,
    required this.dailyData,
    required this.spendingTrend,
    required this.averageTrend,
  });
}
