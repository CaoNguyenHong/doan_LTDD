import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spend_sage/hive/expense.dart';

class CategoryChart extends StatelessWidget {
  final List<Expense> expenses;

  const CategoryChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final categoryData = _calculateCategoryData();

    return Column(
      spacing: 16,
      children: [
        Text(
          'Category Distribution',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _createPieSections(categoryData),
            ),
          ),
        ),
      ],
    );
  }

  // Calculate total amount per category
  Map<String, double> _calculateCategoryData() {
    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }

  // Create pie chart sections with different colors for each category
  List<PieChartSectionData> _createPieSections(
      Map<String, double> categoryData) {
    final total = categoryData.values.fold(0.0, (sum, amount) => sum + amount);
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];

    return categoryData.entries.map((entry) {
      final index = categoryData.keys.toList().indexOf(entry.key);
      final percentage = (entry.value / total) * 100;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }
}
