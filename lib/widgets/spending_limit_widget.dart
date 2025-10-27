import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/budget_provider.dart';
import '../models/transaction.dart' as models;
import '../utils/currency_formatter.dart';

enum TimePeriod {
  day,
  week,
  month,
  year,
}

class SpendingLimitWidget extends StatefulWidget {
  const SpendingLimitWidget({Key? key}) : super(key: key);

  @override
  State<SpendingLimitWidget> createState() => _SpendingLimitWidgetState();
}

class _SpendingLimitWidgetState extends State<SpendingLimitWidget> {
  TimePeriod _selectedPeriod = TimePeriod.month;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer3<TransactionProvider, SettingsProvider, BudgetProvider>(
      builder: (context, transactionProvider, settingsProvider, budgetProvider,
          child) {
        final transactions = transactionProvider.transactions;

        // Get budget limit from BudgetProvider for "toàn bộ" category
        final periodName = _mapTimePeriodToPeriodString(_selectedPeriod);
        final spendingLimit =
            budgetProvider.getTotalBudgetLimitByPeriod(periodName);

        // Debug log
        print('🔍 SpendingLimitWidget: periodName = $periodName');
        print('🔍 SpendingLimitWidget: spendingLimit = $spendingLimit');
        print(
            '🔍 SpendingLimitWidget: budgetProvider.items.length = ${budgetProvider.items.length}');
        for (final budget in budgetProvider.items) {
          print(
              '  - Budget: period=${budget.period}, categoryId=${budget.categoryId}, limit=${budget.limit}');
        }

        // Calculate totals for selected period
        final totals =
            _calculateTotals(transactions, _selectedPeriod, _selectedDate);
        final totalSpending = totals['total'] ?? 0.0;
        final isOverLimit = totalSpending > spendingLimit;
        final progressPercentage =
            spendingLimit > 0 ? (totalSpending / spendingLimit) : 0.0;

        // Extract individual amounts
        final incomeAmount = totals['income'] ?? 0.0;
        final expenseAmount = totals['expense'] ?? 0.0;
        final transferAmount = totals['transfer'] ?? 0.0;
        final refundAmount = totals['refund'] ?? 0.0;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: spendingLimit == 0
                  ? [Colors.grey.shade400, Colors.grey.shade600]
                  : isOverLimit
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : [Colors.green.shade400, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (spendingLimit == 0
                        ? Colors.grey.shade600
                        : isOverLimit
                            ? const Color.fromARGB(255, 239, 42, 28)
                            : const Color.fromARGB(255, 2, 130, 6))
                    .withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chào mừng trở lại!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settingsProvider.userName.isNotEmpty
                            ? settingsProvider.userName
                            : 'SpendSage',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _buildPeriodSelector(),
                ],
              ),
              const SizedBox(height: 16),

              // Header with period selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng chi tiêu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 16),

              // Amount display
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatCurrency(totalSpending),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              spendingLimit == 0
                                  ? Icons.info_outline
                                  : isOverLimit
                                      ? Icons.warning
                                      : Icons.check_circle,
                              color: spendingLimit == 0
                                  ? Colors.white.withOpacity(0.7)
                                  : isOverLimit
                                      ? const Color.fromARGB(255, 251, 2, 2)
                                      : const Color.fromARGB(255, 0, 255, 13),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOverLimit
                                  ? 'Vượt quá ${_formatCurrency(totalSpending - spendingLimit)}'
                                  : spendingLimit > 0
                                      ? 'Còn lại ${_formatCurrency(spendingLimit - totalSpending)}'
                                      : 'Chưa có ngân sách',
                              style: TextStyle(
                                color: isOverLimit
                                    ? const Color.fromARGB(255, 162, 2, 2)
                                    : spendingLimit > 0
                                        ? const Color.fromARGB(255, 0, 253, 13)
                                        : Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Progress indicator
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        '${(progressPercentage * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white.withOpacity(0.3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressPercentage.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: spendingLimit == 0
                          ? Colors.grey.shade300
                          : isOverLimit
                              ? Colors.red.shade300
                              : Colors.green.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Breakdown
              Row(
                children: [
                  Expanded(
                    child: _buildBreakdownItem(
                      'Thu',
                      incomeAmount,
                      Colors.green.shade300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBreakdownItem(
                      'Chi',
                      expenseAmount,
                      Colors.red.shade300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBreakdownItem(
                      'Chuyển',
                      transferAmount,
                      Colors.blue.shade300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBreakdownItem(
                      'Hoàn',
                      refundAmount,
                      Colors.orange.shade300,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<TimePeriod>(
        value: _selectedPeriod,
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black),
        underline: const SizedBox(),
        items: [
          DropdownMenuItem(
            value: TimePeriod.day,
            child: Text('Ngày'),
          ),
          DropdownMenuItem(
            value: TimePeriod.week,
            child: Text('Tuần'),
          ),
          DropdownMenuItem(
            value: TimePeriod.month,
            child: Text('Tháng'),
          ),
          DropdownMenuItem(
            value: TimePeriod.year,
            child: Text('Năm'),
          ),
        ],
        onChanged: (TimePeriod? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedPeriod = newValue;
            });
          }
        },
      ),
    );
  }

  Widget _buildBreakdownItem(String label, double amount, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Map<String, double> _calculateTotals(
    List<models.Transaction> transactions,
    TimePeriod period,
    DateTime selectedDate,
  ) {
    final filteredTransactions = _filterTransactionsByPeriod(
      transactions,
      period,
      selectedDate,
    );

    double income = 0.0;
    double expense = 0.0;
    double transfer = 0.0;
    double refund = 0.0;

    for (final transaction in filteredTransactions) {
      switch (transaction.type) {
        case 'income':
          income += transaction.amount;
          break;
        case 'expense':
          expense += transaction.amount;
          break;
        case 'transfer':
          transfer += transaction.amount;
          break;
        case 'refund':
          refund += transaction.amount;
          break;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'transfer': transfer,
      'refund': refund,
      'total': income + expense + transfer + refund,
    };
  }

  List<models.Transaction> _filterTransactionsByPeriod(
    List<models.Transaction> transactions,
    TimePeriod period,
    DateTime selectedDate,
  ) {
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case TimePeriod.day:
        startDate =
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case TimePeriod.week:
        final weekStart =
            selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case TimePeriod.month:
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
        break;
      case TimePeriod.year:
        startDate = DateTime(selectedDate.year, 1, 1);
        endDate = DateTime(selectedDate.year + 1, 1, 1);
        break;
    }

    return transactions.where((transaction) {
      return transaction.dateTime.isAfter(startDate) &&
          transaction.dateTime.isBefore(endDate);
    }).toList();
  }

  String _mapTimePeriodToPeriodString(TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return 'daily';
      case TimePeriod.week:
        return 'weekly';
      case TimePeriod.month:
        return 'monthly';
      case TimePeriod.year:
        return 'yearly';
    }
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.format(amount);
  }
}
