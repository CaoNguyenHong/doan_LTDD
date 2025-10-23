import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class ExpenseChart extends StatefulWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int? _touchedIndex;
  String _selectedPeriod = 'daily';

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
    final provider = Provider.of<ExpenseProvider>(context);
    final filterMode = provider.filterMode;
    final groupedData = _groupExpenses(widget.expenses, filterMode);
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
            // Header with period selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xu hướng chi tiêu',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3748),
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tổng: \$${totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                _buildPeriodSelector(),
              ],
            ),
            const SizedBox(height: 24),

            // Chart
            SizedBox(
              height: 300,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
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
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final key = groupedData.keys.elementAt(group.x);
                          final value = rod.toY;
                          final percentage = totalAmount > 0
                              ? (value / totalAmount * 100).toStringAsFixed(1)
                              : '0.0';

                          return BarTooltipItem(
                            '$key\n\$${value.toStringAsFixed(2)}\n$percentage%',
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
                            if (index >= 0 && index < groupedData.keys.length) {
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
                            if (value.toInt() % 100 == 0 ||
                                value.toInt() == 0) {
                              return Text(
                                '\$${value.toInt()}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
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

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          isDense: true,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('Ngày')),
            DropdownMenuItem(value: 'weekly', child: Text('Tuần')),
            DropdownMenuItem(value: 'monthly', child: Text('Tháng')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPeriod = value;
              });
            }
          },
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
    final average = totalAmount / groupedData.length;

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
                  '\$${maxEntry.value.toStringAsFixed(2)}',
                  Colors.red.shade600,
                ),
              ),
              Expanded(
                child: _buildInsightItem(
                  'Thấp nhất',
                  minEntry.key,
                  '\$${minEntry.value.toStringAsFixed(2)}',
                  Colors.green.shade600,
                ),
              ),
              Expanded(
                child: _buildInsightItem(
                  'Trung bình',
                  '',
                  '\$${average.toStringAsFixed(2)}',
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
          key = '${expense.dateTime.hour.toString().padLeft(2, '0')}:00';
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
          key = '${expense.dateTime.hour.toString().padLeft(2, '0')}:00';
      }
      grouped[key] = (grouped[key] ?? 0) + expense.amount;
    }

    return Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
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
            width: 24,
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
    return (max * 1.2).ceilToDouble();
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
