import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spend_sage/providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_formatter.dart';

class TotalAmountDisplay extends StatelessWidget {
  const TotalAmountDisplay({super.key});

  Color _getAlertColor(AlertStatus status, BuildContext context) {
    switch (status) {
      case AlertStatus.critical:
        return Colors.red;
      case AlertStatus.warning:
        return Colors.orange;
      case AlertStatus.caution:
        return Colors.yellow;
      case AlertStatus.normal:
        return Colors.green;
      case AlertStatus.none:
        return Theme.of(context).cardColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExpenseProvider, SettingsProvider>(
      builder: (context, expenseProvider, settings, _) {
        final totalAmount = expenseProvider.totalAmount;
        final currency = settings.currency;

        // Get alert status based on current filter mode
        AlertStatus status;

        switch (expenseProvider.filterMode) {
          case 'daily':
            status = settings.getAlertStatus(totalAmount, settings.dailyLimit);
            break;
          case 'weekly':
            status = settings.getAlertStatus(totalAmount, settings.weeklyLimit);
            break;
          case 'monthly':
            status =
                settings.getAlertStatus(totalAmount, settings.monthlyLimit);
            break;
          case 'yearly':
            status = settings.getAlertStatus(totalAmount, settings.yearlyLimit);
            break;
          default:
            status = AlertStatus.none;
        }

        return Card(
          color: _getAlertColor(status, context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              CurrencyFormatter.format(totalAmount, currency: currency),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
        );
      },
    );
  }
}
