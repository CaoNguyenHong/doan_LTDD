import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class FilterSelector extends StatelessWidget {
  const FilterSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) => PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'custom') {
            _showDateRangePicker(context, provider);
          } else {
            provider.setFilterMode(value);
          }
        },
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem(value: 'daily', child: Text('Daily')),
          const PopupMenuItem(value: 'weekly', child: Text('Weekly')),
          const PopupMenuItem(value: 'monthly', child: Text('Monthly')),
          const PopupMenuItem(value: 'yearly', child: Text('Yearly')),
          const PopupMenuItem(value: 'custom', child: Text('Custom Range')),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker(
      BuildContext context, ExpenseProvider provider) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      provider.setCustomDateRange(picked.start, picked.end);
    }
  }
}
