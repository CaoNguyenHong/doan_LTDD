import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spend_sage/hive/expense.dart';

class AdvancedAnalytics extends StatefulWidget {
  final List<Expense> expenses;

  const AdvancedAnalytics({super.key, required this.expenses});

  @override
  State<AdvancedAnalytics> createState() => _AdvancedAnalyticsState();
}

class _AdvancedAnalyticsState extends State<AdvancedAnalytics>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedMetric = 'spending';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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
    final analytics = _calculateAnalytics();

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
                Text(
                  'Phân tích nâng cao',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                ),
                _buildMetricSelector(),
              ],
            ),
            const SizedBox(height: 24),

            // Key Metrics
            _buildKeyMetrics(analytics),
            const SizedBox(height: 24),

            // Trend Chart
            SizedBox(
              height: 200,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildTrendChart(analytics),
              ),
            ),

            // Insights
            const SizedBox(height: 20),
            _buildInsights(analytics),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMetric,
          isDense: true,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            DropdownMenuItem(value: 'spending', child: Text('Chi tiêu')),
            DropdownMenuItem(value: 'frequency', child: Text('Tần suất')),
            DropdownMenuItem(value: 'average', child: Text('Trung bình')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMetric = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(AnalyticsData analytics) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Tổng chi tiêu',
            '\$${analytics.totalSpending.toStringAsFixed(2)}',
            Icons.attach_money,
            const Color(0xFF667eea),
            analytics.spendingTrend,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Số giao dịch',
            '${analytics.totalTransactions}',
            Icons.receipt_long,
            const Color(0xFF48BB78),
            analytics.transactionTrend,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Trung bình',
            '\$${analytics.averageTransaction.toStringAsFixed(2)}',
            Icons.trending_up,
            const Color(0xFFED8936),
            analytics.averageTrend,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, double trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Icon(
                trend > 0 ? Icons.trending_up : Icons.trending_down,
                color: trend > 0 ? Colors.green : Colors.red,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(AnalyticsData analytics) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                    '\$${value.toInt()}',
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
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _createLineSpots(analytics),
              isCurved: true,
              color: const Color(0xFF667eea),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF667eea),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
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

  Widget _buildInsights(AnalyticsData analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Thông tin chi tiết',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            'Chi tiêu cao nhất trong ngày',
            '\$${analytics.highestDailySpending.toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.red,
          ),
          _buildInsightRow(
            'Chi tiêu thấp nhất trong ngày',
            '\$${analytics.lowestDailySpending.toStringAsFixed(2)}',
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

  AnalyticsData _calculateAnalytics() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentExpenses = widget.expenses
        .where((expense) => expense.dateTime.isAfter(thirtyDaysAgo))
        .toList();

    final totalSpending =
        recentExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

    final totalTransactions = recentExpenses.length;
    final averageTransaction =
        totalTransactions > 0 ? totalSpending / totalTransactions : 0.0;

    // Calculate daily spending for the last 30 days
    final dailyData = <double>[];
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayExpenses = recentExpenses
          .where((expense) =>
              expense.dateTime.year == date.year &&
              expense.dateTime.month == date.month &&
              expense.dateTime.day == date.day)
          .toList();
      dailyData
          .add(dayExpenses.fold(0.0, (sum, expense) => sum + expense.amount));
    }

    // Calculate trends (simplified)
    final spendingTrend = _calculateTrend(dailyData);
    final transactionTrend = spendingTrend; // Simplified
    final averageTrend = spendingTrend; // Simplified

    // Find highest and lowest daily spending
    final highestDailySpending =
        dailyData.isNotEmpty ? dailyData.reduce((a, b) => a > b ? a : b) : 0.0;
    final lowestDailySpending =
        dailyData.isNotEmpty ? dailyData.reduce((a, b) => a < b ? a : b) : 0.0;

    return AnalyticsData(
      totalSpending: totalSpending,
      totalTransactions: totalTransactions,
      averageTransaction: averageTransaction,
      spendingTrend: spendingTrend,
      transactionTrend: transactionTrend,
      averageTrend: averageTrend,
      dailyData: dailyData,
      highestDailySpending: highestDailySpending,
      lowestDailySpending: lowestDailySpending,
    );
  }

  double _calculateTrend(List<double> data) {
    if (data.length < 2) return 0.0;
    final firstHalf = data.take(data.length ~/ 2).fold(0.0, (a, b) => a + b);
    final secondHalf = data.skip(data.length ~/ 2).fold(0.0, (a, b) => a + b);
    return secondHalf > firstHalf ? 1.0 : -1.0;
  }

  double _calculateMaxY(AnalyticsData analytics) {
    if (analytics.dailyData.isEmpty) return 100;
    final max = analytics.dailyData.reduce((a, b) => a > b ? a : b);
    return (max * 1.2).ceilToDouble();
  }

  List<FlSpot> _createLineSpots(AnalyticsData analytics) {
    return analytics.dailyData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
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

class AnalyticsData {
  final double totalSpending;
  final int totalTransactions;
  final double averageTransaction;
  final double spendingTrend;
  final double transactionTrend;
  final double averageTrend;
  final List<double> dailyData;
  final double highestDailySpending;
  final double lowestDailySpending;

  AnalyticsData({
    required this.totalSpending,
    required this.totalTransactions,
    required this.averageTransaction,
    required this.spendingTrend,
    required this.transactionTrend,
    required this.averageTrend,
    required this.dailyData,
    required this.highestDailySpending,
    required this.lowestDailySpending,
  });
}
