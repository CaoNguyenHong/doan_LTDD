import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spend_sage/providers/expense_provider.dart';
import 'package:spend_sage/widgets/expense_chart.dart';
import 'package:spend_sage/widgets/category_chart.dart';
import 'package:spend_sage/widgets/chart_totals.dart';
import 'package:spend_sage/widgets/filter_selector.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Expense Analytics'),
          actions: const [FilterSelector()],
        ),
        body: provider.expenses.isEmpty
            ? const Center(
                child: Text('No expenses found for the selected period'),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: ExpenseChart(expenses: provider.expenses),
                    ),
                    SizedBox(
                      height: 300,
                      child: CategoryChart(expenses: provider.expenses),
                    ),
                    ChartTotals(expenses: provider.expenses),
                  ],
                ),
              ),
      ),
    );
  }
}
