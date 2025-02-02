import 'package:flutter/material.dart';
import 'package:spend_sage/hive/expense.dart';

class ChartTotals extends StatelessWidget {
  final List<Expense> expenses;

  const ChartTotals({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _calculateCategoryTotals();
    final total =
        categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Totals',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...categoryTotals.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateCategoryTotals() {
    final Map<String, double> totals = {};
    for (var expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return Map.fromEntries(
        totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }
}
