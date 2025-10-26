import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/settings_provider.dart';
import '../providers/budget_provider.dart';
import '../models/transaction.dart' as models;
import '../utils/currency_formatter.dart';

class ComprehensiveAnalytics extends StatefulWidget {
  final List<models.Transaction> transactions;
  final String selectedPeriod;
  final String selectedTransactionType;
  final DateTime? selectedDate;
  final DateTime? selectedWeekStart;
  final DateTime? selectedMonthStart;

  const ComprehensiveAnalytics({
    super.key,
    required this.transactions,
    required this.selectedPeriod,
    required this.selectedTransactionType,
    this.selectedDate,
    this.selectedWeekStart,
    this.selectedMonthStart,
  });

  @override
  State<ComprehensiveAnalytics> createState() => _ComprehensiveAnalyticsState();
}

class _ComprehensiveAnalyticsState extends State<ComprehensiveAnalytics>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _comparisonPeriod =
      'previous_month'; // previous_day, previous_week, previous_month, previous_year

  // Helpers chuẩn hóa range theo local & [start, end)
  DateTime _startOfDayLocal(DateTime d) => DateTime(d.year, d.month, d.day);

  // Trả về khoảng [start, end) cho KỲ HIỆN TẠI theo lựa chọn
  ({DateTime start, DateTime end}) _currentRange() {
    // Dựa vào widget.selectedPeriod & anchor tương ứng
    switch (widget.selectedPeriod) {
      case 'daily':
        final base =
            _startOfDayLocal((widget.selectedDate ?? DateTime.now()).toLocal());
        return (start: base, end: base.add(const Duration(days: 1)));
      case 'weekly':
        final w0 = _startOfDayLocal(
            (widget.selectedWeekStart ?? DateTime.now()).toLocal());
        return (start: w0, end: w0.add(const Duration(days: 7)));
      case 'monthly':
        final mAnchor = (widget.selectedMonthStart ?? DateTime.now()).toLocal();
        final m0 = DateTime(mAnchor.year, mAnchor.month, 1);
        final m1 = DateTime(m0.year, m0.month + 1, 1);
        return (start: m0, end: m1);
      case 'yearly':
        final yAnchor = (widget.selectedMonthStart ?? DateTime.now()).toLocal();
        final y0 = DateTime(yAnchor.year, 1, 1);
        final y1 = DateTime(yAnchor.year + 1, 1, 1);
        return (start: y0, end: y1);
      default:
        final today0 = _startOfDayLocal(DateTime.now().toLocal());
        return (start: today0, end: today0.add(const Duration(days: 1)));
    }
  }

  ({DateTime start, DateTime end}) _previousRangeOf(
      ({DateTime start, DateTime end}) cur) {
    final len = cur.end.difference(cur.start);
    return (start: cur.start.subtract(len), end: cur.start);
  }

  ({DateTime start, DateTime end}) _combinedRange(
      ({DateTime start, DateTime end}) prev,
      ({DateTime start, DateTime end}) cur) {
    return (start: prev.start, end: cur.end);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Sync comparison period with selected period
    _syncComparisonPeriod();
  }

  void _syncComparisonPeriod() {
    switch (widget.selectedPeriod) {
      case 'daily':
        _comparisonPeriod = 'previous_day';
        break;
      case 'weekly':
        _comparisonPeriod = 'previous_week';
        break;
      case 'monthly':
        _comparisonPeriod = 'previous_month';
        break;
      case 'yearly':
        _comparisonPeriod = 'previous_year';
        break;
      default:
        _comparisonPeriod = 'previous_month';
    }
  }

  @override
  void didUpdateWidget(ComprehensiveAnalytics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _syncComparisonPeriod();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
        '🔍 DEBUG ComprehensiveAnalytics: build() called with ${widget.transactions.length} transactions');
    print('  selectedPeriod: ${widget.selectedPeriod}');
    print('  selectedTransactionType: ${widget.selectedTransactionType}');

    return Consumer2<SettingsProvider, BudgetProvider>(
      builder: (context, settings, budget, _) {
        final filteredTransactions =
            _filterTransactionsByType(widget.transactions);
        final analytics = _calculateComprehensiveAnalytics(
            filteredTransactions, settings, budget);
        final currency = settings.currency;

        if (filteredTransactions.isEmpty) {
          return _buildEmptyState();
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Period Comparison Header
              _buildPeriodComparisonHeader(analytics, currency),
              const SizedBox(height: 20),

              // Key Metrics Cards
              _buildKeyMetricsCards(analytics, currency),
              const SizedBox(height: 20),

              // Category Breakdown with Drill-down
              _buildCategoryBreakdown(analytics, currency),
              const SizedBox(height: 20),

              // Trend Sparkline
              _buildTrendSparkline(analytics, currency),
              const SizedBox(height: 20),

              // Budget Compliance
              if (analytics.budgetData != null) ...[
                _buildBudgetCompliance(analytics.budgetData!, currency),
                const SizedBox(height: 20),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 60,
              color: Color(0xFF667eea),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có dữ liệu phân tích',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hãy thêm một vài giao dịch để xem phân tích chi tiết về thói quen chi tiêu của bạn.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Chuyển đến màn hình chính để thêm giao dịch')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm giao dịch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodComparisonHeader(
      ComprehensiveAnalyticsData analytics, String currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea),
            const Color(0xFF764ba2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'So sánh theo kỳ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_getPeriodDisplayName()} hiện tại',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildComparisonCard(
                  'Kỳ hiện tại',
                  CurrencyFormatter.format(analytics.currentPeriodTotal,
                      currency: currency),
                  analytics.currentPeriodTrend,
                  analytics.currentPeriodTrendColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildComparisonCard(
                  'So với kỳ trước',
                  '${analytics.previousPeriodPercentage.toStringAsFixed(1)}%',
                  analytics.previousPeriodTrend,
                  analytics.previousPeriodTrendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _comparisonPeriod,
          isDense: true,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          dropdownColor: Colors.white,
          items: _getComparisonPeriodItems(),
          onChanged: (value) {
            setState(() {
              _comparisonPeriod = value!;
            });
          },
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getComparisonPeriodItems() {
    switch (widget.selectedPeriod) {
      case 'daily':
        return const [
          DropdownMenuItem(
            value: 'previous_day',
            child: Text('Ngày trước', style: TextStyle(color: Colors.black87)),
          ),
        ];
      case 'weekly':
        return const [
          DropdownMenuItem(
            value: 'previous_week',
            child: Text('Tuần trước', style: TextStyle(color: Colors.black87)),
          ),
        ];
      case 'monthly':
        return const [
          DropdownMenuItem(
            value: 'previous_month',
            child: Text('Tháng trước', style: TextStyle(color: Colors.black87)),
          ),
        ];
      case 'yearly':
        return const [
          DropdownMenuItem(
            value: 'previous_year',
            child: Text('Năm trước', style: TextStyle(color: Colors.black87)),
          ),
        ];
      default:
        return const [
          DropdownMenuItem(
            value: 'previous_month',
            child: Text('Tháng trước', style: TextStyle(color: Colors.black87)),
          ),
        ];
    }
  }

  Widget _buildComparisonCard(
      String title, String value, String trend, Color trendColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Builder(
                builder: (context) {
                  final isUp = trend.contains('▲') ||
                      trend.toLowerCase().contains('tăng');
                  return Icon(isUp ? Icons.trending_up : Icons.trending_down,
                      color: trendColor, size: 16);
                },
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  color: trendColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsCards(
      ComprehensiveAnalyticsData analytics, String currency) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Tổng ${_getTransactionTypeDisplayName()}',
            CurrencyFormatter.format(analytics.currentPeriodTotal,
                currency: currency),
            _getTransactionTypeIcon(),
            _getTransactionTypeColor(),
            analytics.currentPeriodTrend,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Trung bình/ngày',
            CurrencyFormatter.format(analytics.dailyAverage,
                currency: currency),
            Icons.trending_up,
            const Color(0xFFED8936),
            analytics.dailyTrend,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Số giao dịch',
            '${analytics.transactionCount}',
            Icons.receipt_long,
            const Color(0xFF38B2AC),
            analytics.transactionTrend,
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

  Widget _buildCategoryBreakdown(
      ComprehensiveAnalyticsData analytics, String currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: const Color(0xFF667eea), size: 20),
              const SizedBox(width: 8),
              Text(
                'Phân bổ theo danh mục',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Category List with Drill-down
          ...analytics.categoryBreakdown.entries.map((entry) {
            final category = entry.key;
            final data = entry.value;
            final percentage = analytics.currentPeriodTotal > 0
                ? (data['amount'] / analytics.currentPeriodTotal * 100)
                : 0.0;

            return GestureDetector(
              onTap: () => _showCategoryDrillDown(category, analytics),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    // Category Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: _getCategoryColor(category),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Category Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${data['count']} giao dịch • ${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Progress bar
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.grey.shade200,
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: percentage / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: _getCategoryColor(category),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Amount and Arrow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(data['amount'],
                              currency: currency),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getCategoryColor(category),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade400,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTrendSparkline(
      ComprehensiveAnalyticsData analytics, String currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: const Color(0xFF667eea), size: 20),
              const SizedBox(width: 8),
              Text(
                'Xu hướng ${_getTransactionTypeDisplayName().toLowerCase()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mini Sparkline Chart
          SizedBox(
            height: 60,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: analytics.dailyTrendData,
                    isCurved: true,
                    color: const Color(0xFF667eea),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF667eea).withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: analytics.maxDailyAmount,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Trend Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Xu hướng ${analytics.overallTrend}',
                style: TextStyle(
                  color: analytics.overallTrendColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '${analytics.dailyTrendData.length} ngày',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCompliance(BudgetData budgetData, String currency) {
    final percentage = (budgetData.usedAmount / budgetData.totalAmount * 100);
    final remaining = budgetData.totalAmount - budgetData.usedAmount;
    final isOverBudget = budgetData.usedAmount > budgetData.totalAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: const Color(0xFF667eea), size: 20),
              const SizedBox(width: 8),
              Text(
                'Tuân thủ ngân sách',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Budget Progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isOverBudget ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isOverBudget ? Colors.red.shade200 : Colors.green.shade200,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã dùng',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}% ngân sách',
                      style: TextStyle(
                        color: isOverBudget
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade200,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (percentage / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isOverBudget ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Còn lại',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      isOverBudget
                          ? 'Vượt ${CurrencyFormatter.format(-remaining, currency: currency)}'
                          : 'Còn ${CurrencyFormatter.format(remaining, currency: currency)}',
                      style: TextStyle(
                        color: isOverBudget
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Estimation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOverBudget ? Icons.warning : Icons.check_circle,
                        color: isOverBudget ? Colors.red : Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isOverBudget
                              ? 'Ước tính vượt ngân sách ${budgetData.estimatedOverspend.toStringAsFixed(0)}%'
                              : 'Ước tính đạt mục tiêu ngân sách',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDrillDown(
      String category, ComprehensiveAnalyticsData analytics) {
    final transactions = analytics.categoryTransactions[category] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: _getCategoryColor(category),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${transactions.length} giao dịch',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Transactions List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${transaction.dateTime.day}/${transaction.dateTime.month}/${transaction.dateTime.year}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(transaction.amount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getTransactionTypeColor(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<models.Transaction> _filterTransactionsByType(
      List<models.Transaction> transactions) {
    return transactions
        .where((t) => t.type == widget.selectedTransactionType)
        .toList();
  }

  ComprehensiveAnalyticsData _calculateComprehensiveAnalytics(
    List<models.Transaction> transactions,
    SettingsProvider settings,
    BudgetProvider budget,
  ) {
    // Debug: Log all transactions
    print('🔍 DEBUG All Transactions:');
    print('  Total transactions: ${transactions.length}');
    for (var t in transactions.take(10)) {
      // Show first 10
      print('    ${t.dateTime}: ${t.amount} VND (${t.type})');
    }
    final filteredTransactions = transactions
        .where((t) => t.type == widget.selectedTransactionType)
        .toList();

    print(
        '🔍 DEBUG Filtered Transactions (${widget.selectedTransactionType}):');
    print('  Total filtered: ${filteredTransactions.length}');
    for (var t in filteredTransactions.take(10)) {
      print('    ${t.dateTime}: ${t.amount} VND');
    }

    if (filteredTransactions.isEmpty) {
      return ComprehensiveAnalyticsData.empty();
    }

    // Thay toàn bộ logic xác định kỳ hiện tại/kỳ trước bằng helpers ở trên
    final rangeCur = _currentRange();
    final rangePrev = _previousRangeOf(rangeCur);
    final rangeAll = _combinedRange(rangePrev, rangeCur);

    // Logging: cập nhật log in/out ranges để debug
    print('🔍 Current Range: ${rangeCur.start} -> ${rangeCur.end}');
    print('🔍 Previous Range: ${rangePrev.start} -> ${rangePrev.end}');
    print('🔍 Combined Range: ${rangeAll.start} -> ${rangeAll.end}');

    // Lọc theo loại + khoảng combined
    final filtered = transactions.where((t) {
      if (t.type != widget.selectedTransactionType) return false;
      final dt = t.dateTime.toLocal();
      return !dt.isBefore(rangeAll.start) && dt.isBefore(rangeAll.end);
    }).toList();

    // Chia current vs previous
    final currentPeriodTx = filtered.where((t) {
      final dt = t.dateTime.toLocal();
      return !dt.isBefore(rangeCur.start) && dt.isBefore(rangeCur.end);
    }).toList();

    final previousPeriodTx = filtered.where((t) {
      final dt = t.dateTime.toLocal();
      return !dt.isBefore(rangePrev.start) && dt.isBefore(rangePrev.end);
    }).toList();

    print(
        '🔍 Tx filtered(count=${filtered.length}) cur=${currentPeriodTx.length} prev=${previousPeriodTx.length}');

    final currentPeriodTotal =
        currentPeriodTx.fold(0.0, (s, x) => s + x.amount);
    final previousPeriodTotal =
        previousPeriodTx.fold(0.0, (s, x) => s + x.amount);
    final dailyAverage = currentPeriodTotal / _getDaysInCurrentPeriod();
    final transactionCount = currentPeriodTx.length;

    // Tính % thay đổi theo quy tắc "trống = 0"
    double changePercent;
    String previousPeriodTrend;
    Color previousPeriodTrendColor;

    if (previousPeriodTotal == 0 && currentPeriodTotal == 0) {
      changePercent = 0.0;
      previousPeriodTrend = '0% (không đổi)';
      previousPeriodTrendColor = Colors.grey;
    } else if (previousPeriodTotal == 0 && currentPeriodTotal > 0) {
      changePercent = 100.0;
      previousPeriodTrend = '▲ 100%';
      previousPeriodTrendColor = Colors.green;
    } else if (previousPeriodTotal > 0 && currentPeriodTotal == 0) {
      changePercent = -100.0;
      previousPeriodTrend = '▼ 100%';
      previousPeriodTrendColor = Colors.red;
    } else {
      final raw =
          ((currentPeriodTotal - previousPeriodTotal) / previousPeriodTotal) *
              100.0;
      changePercent = raw;
      previousPeriodTrend = raw >= 0
          ? '▲ ${raw.toStringAsFixed(1)}%'
          : '▼ ${(-raw).toStringAsFixed(1)}%';
      previousPeriodTrendColor = raw >= 0 ? Colors.green : Colors.red;
    }

    // Calculate trends
    final currentPeriodTrend = _calculateTrend(currentPeriodTx);
    final dailyTrend = _calculateDailyTrend(currentPeriodTx);
    final transactionTrend = _calculateTransactionTrend(currentPeriodTx);

    // Calculate category breakdown
    final categoryBreakdown = <String, Map<String, dynamic>>{};
    final categoryTransactions = <String, List<models.Transaction>>{};

    for (var transaction in currentPeriodTx) {
      final category = transaction.categoryId ?? 'other';
      if (!categoryBreakdown.containsKey(category)) {
        categoryBreakdown[category] = {'amount': 0.0, 'count': 0};
        categoryTransactions[category] = [];
      }
      categoryBreakdown[category]!['amount'] += transaction.amount;
      categoryBreakdown[category]!['count'] += 1;
      categoryTransactions[category]!.add(transaction);
    }

    // Sort categories by amount
    final sortedCategories = Map.fromEntries(categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value['amount'].compareTo(a.value['amount'])));

    // Calculate daily trend data for sparkline
    final dailyTrendData = _calculateDailyTrendData(currentPeriodTx);
    final maxDailyAmount = dailyTrendData.isNotEmpty
        ? dailyTrendData.map((e) => e.y).reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Calculate overall trend
    final overallTrend = _calculateOverallTrend(dailyTrendData);
    final overallTrendColor =
        overallTrend.contains('Tăng') ? Colors.green : Colors.red;

    // Calculate budget data
    BudgetData? budgetData;
    if (widget.selectedTransactionType == 'expense') {
      final budgetAmount = _getBudgetAmount(budget, settings);
      if (budgetAmount > 0) {
        final estimatedOverspend =
            (currentPeriodTotal / budgetAmount * 100) - 100;
        budgetData = BudgetData(
          totalAmount: budgetAmount,
          usedAmount: currentPeriodTotal,
          estimatedOverspend: estimatedOverspend,
        );
      }
    }

    return ComprehensiveAnalyticsData(
      currentPeriodTotal: currentPeriodTotal,
      dailyAverage: dailyAverage,
      transactionCount: transactionCount,
      currentPeriodTrend: currentPeriodTrend,
      currentPeriodTrendColor: currentPeriodTrend.contains('Tăng')
          ? Colors.green
          : currentPeriodTrend.contains('Giảm')
              ? Colors.red
              : Colors.grey,
      dailyTrend: dailyTrend,
      transactionTrend: transactionTrend,
      previousPeriodTotal: previousPeriodTotal,
      previousPeriodPercentage: changePercent, // luôn có giá trị
      previousPeriodTrend: previousPeriodTrend,
      previousPeriodTrendColor: previousPeriodTrendColor,
      categoryBreakdown: sortedCategories,
      categoryTransactions: categoryTransactions,
      dailyTrendData: dailyTrendData,
      maxDailyAmount: maxDailyAmount,
      overallTrend: overallTrend,
      overallTrendColor: overallTrendColor,
      budgetData: budgetData,
    );
  }

  int _getDaysInCurrentPeriod() {
    final r = _currentRange();
    return r.end.difference(r.start).inDays.clamp(1, 366);
  }

  List<FlSpot> _calculateDailyTrendData(List<models.Transaction> transactions) {
    final dailyTotals = <DateTime, double>{};
    for (var transaction in transactions) {
      final day = _startOfDayLocal(transaction.dateTime.toLocal());
      dailyTotals[day] = (dailyTotals[day] ?? 0) + transaction.amount;
    }

    final sortedDays = dailyTotals.keys.toList()..sort();
    return sortedDays.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dailyTotals[entry.value]!);
    }).toList();
  }

  String _calculateOverallTrend(List<FlSpot> dailyData) {
    if (dailyData.length < 2) return 'Dữ liệu chưa đủ';

    final firstHalf = dailyData
        .take(dailyData.length ~/ 2)
        .fold(0.0, (sum, spot) => sum + spot.y);
    final secondHalf = dailyData
        .skip(dailyData.length ~/ 2)
        .fold(0.0, (sum, spot) => sum + spot.y);

    if (secondHalf > firstHalf * 1.1) return 'Tăng mạnh';
    if (secondHalf > firstHalf * 1.05) return 'Tăng nhẹ';
    if (secondHalf < firstHalf * 0.9) return 'Giảm mạnh';
    if (secondHalf < firstHalf * 0.95) return 'Giảm nhẹ';
    return 'Ổn định';
  }

  double _getBudgetAmount(BudgetProvider budget, SettingsProvider settings) {
    // This would integrate with your budget system
    return 0.0; // Placeholder
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

  String _calculateTransactionTrend(List<models.Transaction> transactions) {
    if (transactions.length < 7) return 'Dữ liệu chưa đủ';

    final dailyCounts = <DateTime, int>{};
    for (var transaction in transactions) {
      final day = DateTime(transaction.dateTime.year,
          transaction.dateTime.month, transaction.dateTime.day);
      dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
    }

    final sortedDays = dailyCounts.keys.toList()..sort();
    if (sortedDays.length < 2) return 'Dữ liệu chưa đủ';

    final recent = sortedDays.length >= 3
        ? sortedDays
            .skip(sortedDays.length - 3)
            .fold(0, (sum, day) => sum + dailyCounts[day]!)
        : sortedDays.fold(0, (sum, day) => sum + dailyCounts[day]!);
    final earlier = sortedDays.length >= 3
        ? sortedDays
            .take(sortedDays.length - 3)
            .fold(0, (sum, day) => sum + dailyCounts[day]!)
        : 0;

    if (recent > earlier * 1.1) return 'Tăng mạnh';
    if (recent > earlier * 1.05) return 'Tăng nhẹ';
    if (recent < earlier * 0.9) return 'Giảm mạnh';
    if (recent < earlier * 0.95) return 'Giảm nhẹ';
    return 'Ổn định';
  }

  String _getPeriodDisplayName() {
    switch (widget.selectedPeriod) {
      case 'daily':
        return 'Ngày';
      case 'weekly':
        return 'Tuần';
      case 'monthly':
        return 'Tháng';
      case 'yearly':
        return 'Năm';
      default:
        return 'Kỳ';
    }
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFE53E3E);
      case 'transport':
        return const Color(0xFF3182CE);
      case 'shopping':
        return const Color(0xFF9F7AEA);
      case 'entertainment':
        return const Color(0xFFED8936);
      case 'utilities':
        return const Color(0xFF38B2AC);
      case 'health':
        return const Color(0xFF48BB78);
      case 'education':
        return const Color(0xFF4299E1);
      default:
        return const Color(0xFF718096);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.power;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }
}

class ComprehensiveAnalyticsData {
  final double currentPeriodTotal;
  final double dailyAverage;
  final int transactionCount;
  final String currentPeriodTrend;
  final Color currentPeriodTrendColor;
  final String dailyTrend;
  final String transactionTrend;
  final double previousPeriodTotal;
  final double previousPeriodPercentage;
  final String previousPeriodTrend;
  final Color previousPeriodTrendColor;
  final Map<String, Map<String, dynamic>> categoryBreakdown;
  final Map<String, List<models.Transaction>> categoryTransactions;
  final List<FlSpot> dailyTrendData;
  final double maxDailyAmount;
  final String overallTrend;
  final Color overallTrendColor;
  final BudgetData? budgetData;

  ComprehensiveAnalyticsData({
    required this.currentPeriodTotal,
    required this.dailyAverage,
    required this.transactionCount,
    required this.currentPeriodTrend,
    required this.currentPeriodTrendColor,
    required this.dailyTrend,
    required this.transactionTrend,
    required this.previousPeriodTotal,
    required this.previousPeriodPercentage,
    required this.previousPeriodTrend,
    required this.previousPeriodTrendColor,
    required this.categoryBreakdown,
    required this.categoryTransactions,
    required this.dailyTrendData,
    required this.maxDailyAmount,
    required this.overallTrend,
    required this.overallTrendColor,
    this.budgetData,
  });

  factory ComprehensiveAnalyticsData.empty() {
    return ComprehensiveAnalyticsData(
      currentPeriodTotal: 0.0,
      dailyAverage: 0.0,
      transactionCount: 0,
      currentPeriodTrend: 'Dữ liệu chưa đủ',
      currentPeriodTrendColor: Colors.grey,
      dailyTrend: 'Dữ liệu chưa đủ',
      transactionTrend: 'Dữ liệu chưa đủ',
      previousPeriodTotal: 0.0,
      previousPeriodPercentage: 0.0,
      previousPeriodTrend: 'Dữ liệu chưa đủ',
      previousPeriodTrendColor: Colors.grey,
      categoryBreakdown: {},
      categoryTransactions: {},
      dailyTrendData: [],
      maxDailyAmount: 0.0,
      overallTrend: 'Dữ liệu chưa đủ',
      overallTrendColor: Colors.grey,
      budgetData: null,
    );
  }
}

class BudgetData {
  final double totalAmount;
  final double usedAmount;
  final double estimatedOverspend;

  BudgetData({
    required this.totalAmount,
    required this.usedAmount,
    required this.estimatedOverspend,
  });
}
