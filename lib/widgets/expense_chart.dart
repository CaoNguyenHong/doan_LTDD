import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spend_sage/hive/expense.dart';
import '../utils/currency_formatter.dart';

class ExpenseChart extends StatefulWidget {
  final List<Expense> expenses;
  final String period; // daily, weekly, monthly

  const ExpenseChart({
    super.key,
    required this.expenses,
    this.period = 'daily',
  });

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
    final groupedData = _groupExpenses(widget.expenses, widget.period);
    final totalAmount =
        groupedData.values.fold(0.0, (sum, amount) => sum + amount);

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xu hướng chi tiêu',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tổng: ${CurrencyFormatter.format(totalAmount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chart with horizontal scroll
            SizedBox(
              height: 300,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(
                      right: 50, top: 20), // Thêm padding phía trên và bên phải
                  child: SizedBox(
                    width: _calculateChartWidth(groupedData),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceBetween,
                        groupsSpace: 8, // Khoảng cách cố định giữa các nhóm cột
                        maxY: _calculateMaxY(groupedData),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.black87,
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            tooltipHorizontalAlignment: FLHorizontalAlignment
                                .center, // Căn giữa tooltip
                            tooltipMargin: 8, // Khoảng cách từ cột
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final key = groupedData.keys.elementAt(group.x);
                              final value = rod.toY;
                              final percentage = totalAmount > 0
                                  ? (value / totalAmount * 100)
                                      .toStringAsFixed(1)
                                  : '0.0';

                              return BarTooltipItem(
                                '$key\n${CurrencyFormatter.format(value)}\n$percentage%',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                          touchCallback: (event, response) {
                            if (response?.spot != null) {
                              setState(() {
                                _touchedIndex =
                                    response!.spot!.touchedBarGroupIndex;
                              });
                            }
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < groupedData.keys.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      groupedData.keys.elementAt(index),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                // Tính mức cao nhất: giá trị cao nhất + 500,000 VND, làm tròn lên hàng triệu
                                final maxDataValue = meta.max;
                                double topLevel;

                                // Cộng thêm 500,000 VND và làm tròn lên hàng triệu
                                final valueWithBuffer = maxDataValue + 500000;
                                topLevel = ((valueWithBuffer / 1000000).ceil() *
                                        1000000)
                                    .toDouble();

                                // Chia thành 4 khoảng đều nhau: 0, step, 2*step, 3*step, topLevel
                                final step = topLevel / 4;
                                final levels = [
                                  0.0,
                                  step,
                                  2 * step,
                                  3 * step,
                                  topLevel
                                ];

                                // Kiểm tra xem value có gần với một trong các mức không
                                for (final level in levels) {
                                  if ((value - level).abs() < 1000.0) {
                                    // Tăng tolerance lên 1000 để chắc chắn
                                    return Text(
                                      CurrencyFormatter.format(level),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  }
                                }
                                return const Text('');
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
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        barGroups: _createBarGroups(groupedData),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _calculateMaxY(groupedData) / 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade100,
                              strokeWidth: 1,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Insights
            if (groupedData.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildInsights(groupedData, totalAmount),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsights(Map<String, double> groupedData, double totalAmount) {
    if (groupedData.isEmpty) return const SizedBox.shrink();

    final maxEntry =
        groupedData.entries.reduce((a, b) => a.value > b.value ? a : b);
    final minEntry =
        groupedData.entries.reduce((a, b) => a.value < b.value ? a : b);

    // Tính trung bình theo khoảng thời gian
    double average;
    String averageLabel;

    if (widget.period == 'daily') {
      // Ngày: trung bình mỗi giờ
      average = totalAmount / 24; // Chia cho 24 giờ
      averageLabel = 'Trung bình/giờ';
    } else if (widget.period == 'weekly') {
      // Tuần: trung bình mỗi ngày
      average = totalAmount / 7; // Chia cho 7 ngày
      averageLabel = 'Trung bình/ngày';
    } else if (widget.period == 'monthly') {
      // Tháng: trung bình mỗi tuần (chia 4)
      average = totalAmount / 4; // Chia cho 4 tuần
      averageLabel = 'Trung bình/tuần';
    } else {
      // Mặc định: trung bình theo số lượng giao dịch
      average = totalAmount / groupedData.length;
      averageLabel = 'Trung bình';
    }

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
              Icon(Icons.insights, color: Colors.blue.shade600, size: 20),
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
          Row(
            children: [
              Expanded(
                child: _buildInsightItem(
                  'Cao nhất',
                  maxEntry.key,
                  CurrencyFormatter.format(maxEntry.value),
                  Colors.red.shade600,
                ),
              ),
              Expanded(
                child: _buildInsightItem(
                  'Thấp nhất',
                  minEntry.key,
                  CurrencyFormatter.format(minEntry.value),
                  Colors.green.shade600,
                ),
              ),
              Expanded(
                child: _buildInsightItem(
                  averageLabel,
                  '',
                  CurrencyFormatter.format(average),
                  Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
      String label, String period, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          period.isNotEmpty ? period : '',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
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
    );
  }

  Map<String, double> _groupExpenses(
      List<Expense> expenses, String filterMode) {
    final Map<String, double> grouped = {};

    for (var expense in expenses) {
      String key;
      switch (filterMode) {
        case 'daily':
          // Hiển thị thời gian thực (giờ:phút)
          key =
              '${expense.dateTime.hour.toString().padLeft(2, '0')}:${expense.dateTime.minute.toString().padLeft(2, '0')}';
          break;
        case 'weekly':
          key = _weekdayToString(expense.dateTime.weekday);
          break;
        case 'monthly':
          key = '${expense.dateTime.day}/${expense.dateTime.month}';
          break;
        case 'yearly':
          key = _monthToString(expense.dateTime.month);
          break;
        default:
          key =
              '${expense.dateTime.hour.toString().padLeft(2, '0')}:${expense.dateTime.minute.toString().padLeft(2, '0')}';
      }
      grouped[key] = (grouped[key] ?? 0) + expense.amount;
    }

    // Sort by time for daily mode, otherwise by key
    if (filterMode == 'daily') {
      return Map.fromEntries(
          grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    } else {
      return Map.fromEntries(
          grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    }
  }

  List<BarChartGroupData> _createBarGroups(Map<String, double> groupedData) {
    return groupedData.entries.map((entry) {
      final index = groupedData.keys.toList().indexOf(entry.key);
      final isTouched = index >= 0 && index == _touchedIndex;

      return BarChartGroupData(
        x: index >= 0 ? index : 0,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: isTouched
                ? const Color(0xFF667eea)
                : const Color(0xFF667eea).withOpacity(0.7),
            width: 20, // Giảm width để có nhiều không gian hơn
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              color: Colors.grey.shade100,
            ),
          ),
        ],
      );
    }).toList();
  }

  double _calculateMaxY(Map<String, double> groupedData) {
    if (groupedData.isEmpty) return 100;
    final max = groupedData.values.reduce((a, b) => a > b ? a : b);

    // Cộng thêm 500,000 VND và làm tròn lên hàng triệu
    final valueWithBuffer = max + 500000;
    final topLevel = ((valueWithBuffer / 1000000).ceil() * 1000000).toDouble();

    return topLevel;
  }

  double _calculateChartWidth(Map<String, double> groupedData) {
    // Calculate width based on number of bars
    // Each bar needs about 50px width + 8px spacing to prevent overlap
    final barCount = groupedData.length;
    final minWidth = barCount * 58.0; // 50px bar + 8px spacing
    // Add more padding at the end to allow scrolling beyond last column
    final padding = 200.0; // Tăng padding để có thể kéo thêm một chút nữa
    return minWidth > 300 ? minWidth + padding : 300 + padding;
  }

  String _weekdayToString(int weekday) {
    const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return weekdays[weekday % 7];
  }

  String _monthToString(int month) {
    const months = [
      'T1',
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'T8',
      'T9',
      'T10',
      'T11',
      'T12'
    ];
    return months[month - 1];
  }
}
