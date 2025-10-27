import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart' as models;
import '../utils/currency_formatter.dart';

class HistoryAnalyticsScreen extends StatefulWidget {
  const HistoryAnalyticsScreen({super.key});

  @override
  State<HistoryAnalyticsScreen> createState() => _HistoryAnalyticsScreenState();
}

class _HistoryAnalyticsScreenState extends State<HistoryAnalyticsScreen>
    with TickerProviderStateMixin {
  String _selectedPeriod = 'month';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Phân tích chi tiêu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        toolbarHeight: 80,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('Tuần')),
              const PopupMenuItem(value: 'month', child: Text('Tháng')),
              const PopupMenuItem(value: 'year', child: Text('Năm')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Xu hướng'),
            Tab(text: 'Danh mục'),
            Tab(text: 'So sánh'),
          ],
        ),
      ),
      body: Consumer2<TransactionProvider, SettingsProvider>(
        builder: (context, transactionProvider, settingsProvider, _) {
          final transactions =
              _getFilteredTransactions(transactionProvider.transactions);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTrendChart(transactions, settingsProvider),
              _buildCategoryChart(transactions, settingsProvider),
              _buildComparisonChart(transactions, settingsProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrendChart(
      List<models.Transaction> transactions, SettingsProvider settings) {
    final chartData = _prepareTrendData(transactions);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Cards
          _buildSummaryCards(transactions, settings),
          const SizedBox(height: 20),

          // Chart
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xu hướng chi tiêu theo ${_getPeriodName()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    CurrencyFormatter.formatCompact(value),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    _getXAxisLabel(value.toInt()),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: chartData['expense']!,
                              isCurved: true,
                              color: Colors.red,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.red.withOpacity(0.1),
                              ),
                            ),
                            LineChartBarData(
                              spots: chartData['income']!,
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.green.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(
      List<models.Transaction> transactions, SettingsProvider settings) {
    final categoryData = _prepareCategoryData(transactions);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary
          _buildCategorySummary(categoryData, settings),
          const SizedBox(height: 20),

          // Pie Chart
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phân bổ chi tiêu theo danh mục',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: PieChart(
                              PieChartData(
                                sections: _buildPieChartSections(categoryData),
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: _buildCategoryLegend(categoryData),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChart(
      List<models.Transaction> transactions, SettingsProvider settings) {
    final comparisonData = _prepareComparisonData(transactions);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary
          _buildComparisonSummary(comparisonData, settings),
          const SizedBox(height: 20),

          // Bar Chart
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'So sánh thu chi theo ${_getPeriodName()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: comparisonData['max']!,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    CurrencyFormatter.formatCompact(value),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    _getComparisonXAxisLabel(value.toInt()),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          barGroups: _buildBarChartGroups(comparisonData),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
      List<models.Transaction> transactions, SettingsProvider settings) {
    double totalIncome = 0;
    double totalExpense = 0;
    double netAmount = 0;

    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      } else if (transaction.type == 'expense') {
        totalExpense += transaction.amount;
      }
    }

    netAmount = totalIncome - totalExpense;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Thu nhập',
            totalIncome,
            Colors.green,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Chi tiêu',
            totalExpense,
            Colors.red,
            Icons.trending_down,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Còn lại',
            netAmount,
            netAmount >= 0 ? Colors.blue : Colors.orange,
            Icons.account_balance_wallet,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySummary(
      Map<String, double> categoryData, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan danh mục',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...categoryData.entries.map((entry) {
            final percentage =
                (entry.value / categoryData.values.fold(0.0, (a, b) => a + b)) *
                    100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.key),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getCategoryDisplayName(entry.key),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryLegend(Map<String, double> categoryData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoryData.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getCategoryColor(entry.key),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getCategoryDisplayName(entry.key),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComparisonSummary(
      Map<String, dynamic> comparisonData, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'So sánh thu chi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildComparisonItem(
                  'Thu nhập',
                  comparisonData['income']!,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildComparisonItem(
                  'Chi tiêu',
                  comparisonData['expense']!,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String title, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<models.Transaction> _getFilteredTransactions(
      List<models.Transaction> transactions) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return transactions.where((t) {
      return t.dateTime.isAfter(startDate) && t.dateTime.isBefore(endDate);
    }).toList();
  }

  Map<String, List<FlSpot>> _prepareTrendData(
      List<models.Transaction> transactions) {
    // Group transactions by day/week/month
    final Map<String, Map<String, double>> groupedData = {};

    for (final transaction in transactions) {
      String periodKey;
      switch (_selectedPeriod) {
        case 'week':
          periodKey =
              '${transaction.dateTime.year}-W${_getWeekNumber(transaction.dateTime)}';
          break;
        case 'month':
          periodKey =
              '${transaction.dateTime.year}-${transaction.dateTime.month}';
          break;
        case 'year':
          periodKey = '${transaction.dateTime.year}';
          break;
        default:
          periodKey =
              '${transaction.dateTime.year}-${transaction.dateTime.month}-${transaction.dateTime.day}';
      }

      if (!groupedData.containsKey(periodKey)) {
        groupedData[periodKey] = {'income': 0, 'expense': 0};
      }

      if (transaction.type == 'income') {
        groupedData[periodKey]!['income'] =
            groupedData[periodKey]!['income']! + transaction.amount;
      } else if (transaction.type == 'expense') {
        groupedData[periodKey]!['expense'] =
            groupedData[periodKey]!['expense']! + transaction.amount;
      }
    }

    // Convert to FlSpot data
    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];

    int index = 0;
    for (final entry in groupedData.entries) {
      incomeSpots.add(FlSpot(index.toDouble(), entry.value['income']!));
      expenseSpots.add(FlSpot(index.toDouble(), entry.value['expense']!));
      index++;
    }

    return {
      'income': incomeSpots,
      'expense': expenseSpots,
    };
  }

  Map<String, double> _prepareCategoryData(
      List<models.Transaction> transactions) {
    final Map<String, double> categoryData = {};

    for (final transaction in transactions) {
      if (transaction.type == 'expense') {
        final category = transaction.categoryId ?? 'other';
        categoryData[category] =
            (categoryData[category] ?? 0) + transaction.amount;
      }
    }

    return categoryData;
  }

  Map<String, dynamic> _prepareComparisonData(
      List<models.Transaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      } else if (transaction.type == 'expense') {
        totalExpense += transaction.amount;
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'max': [totalIncome, totalExpense].reduce((a, b) => a > b ? a : b) * 1.2,
    };
  }

  List<PieChartSectionData> _buildPieChartSections(
      Map<String, double> categoryData) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    int colorIndex = 0;
    return categoryData.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title:
            '${(entry.value / categoryData.values.fold(0.0, (a, b) => a + b) * 100).toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _buildBarChartGroups(
      Map<String, dynamic> comparisonData) {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: comparisonData['income']!,
            color: Colors.green,
            width: 20,
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: comparisonData['expense']!,
            color: Colors.red,
            width: 20,
          ),
        ],
      ),
    ];
  }

  String _getPeriodName() {
    switch (_selectedPeriod) {
      case 'week':
        return 'tuần';
      case 'month':
        return 'tháng';
      case 'year':
        return 'năm';
      default:
        return 'tháng';
    }
  }

  String _getXAxisLabel(int index) {
    // This would need to be implemented based on the actual data
    return '${index + 1}';
  }

  String _getComparisonXAxisLabel(int index) {
    return index == 0 ? 'Thu nhập' : 'Chi tiêu';
  }

  String _getCategoryDisplayName(String categoryId) {
    const categoryMap = {
      'food': 'Ăn uống',
      'transport': 'Di chuyển',
      'shopping': 'Mua sắm',
      'entertainment': 'Giải trí',
      'health': 'Sức khỏe',
      'education': 'Giáo dục',
      'utilities': 'Tiện ích',
      'other': 'Khác',
    };
    return categoryMap[categoryId] ?? 'Khác';
  }

  Color _getCategoryColor(String categoryId) {
    const colorMap = {
      'food': Colors.red,
      'transport': Colors.blue,
      'shopping': Colors.purple,
      'entertainment': Colors.orange,
      'health': Colors.green,
      'education': Colors.teal,
      'utilities': Colors.indigo,
      'other': Colors.grey,
    };
    return colorMap[categoryId] ?? Colors.grey;
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return (dayOfYear / 7).ceil();
  }
}
