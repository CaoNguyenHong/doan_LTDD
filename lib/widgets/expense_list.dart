import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:spend_sage/utilities/utilities.dart';
import '../providers/expense_provider.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseList({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text('Không có chi tiêu cho khoảng thời gian này'),
      );
    }

    return Column(
      children: expenses.map((expense) {
        return Dismissible(
          key: Key(expense.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            Provider.of<ExpenseProvider>(context, listen: false)
                .deleteExpense(expense.id);
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                _getCategoryIcon(expense.category),
                color: Colors.white,
              ),
            ),
            title: Text(
              expense.description,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${_getCategoryDisplayName(expense.category)} • ${_formatDate(expense.dateTime)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            trailing: Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _showEditDialog(context, expense),
          ),
        );
      }).toList(),
    );
  }

  void _showEditDialog(BuildContext context, Expense expense) {
    final TextEditingController descriptionController = TextEditingController(
      text: expense.description,
    );
    final TextEditingController amountController = TextEditingController(
      text: expense.amount.toString(),
    );
    String selectedCategory = expense.category;

    Utilities.showAnimatedDialog(
      context: context,
      title: 'Chỉnh sửa chi tiêu',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                labelText: 'Mô tả',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Danh mục',
              ),
              items: [
                'food',
                'transport',
                'utilities',
                'health',
                'education',
                'shopping',
                'entertainment',
                'other'
              ].map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryDisplayName(category)),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  selectedCategory = value;
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () async {
            final expenseProvider = context.read<ExpenseProvider>();
            final double? amount = double.tryParse(amountController.text);
            if (amount != null) {
              // update the expense
              await expenseProvider.updateExpense(
                expense.id,
                descriptionController.text,
                amount,
                selectedCategory,
              );

              // update category learning
              // Learn from this correction
              await expenseProvider.correctExpenseCategory(
                expense.description,
                selectedCategory,
              );

              if (context.mounted) {
                // Close the dialog
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    );

    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: const Text('Edit Expense'),
    //     content: SingleChildScrollView(
    //       child: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           TextField(
    //             controller: descriptionController,
    //             decoration: const InputDecoration(
    //               labelText: 'Description',
    //             ),
    //           ),
    //           const SizedBox(height: 16),
    //           TextField(
    //             controller: amountController,
    //             decoration: const InputDecoration(
    //               labelText: 'Amount',
    //               prefixText: '\$',
    //             ),
    //             keyboardType: TextInputType.number,
    //           ),
    //           const SizedBox(height: 16),
    //           DropdownButtonFormField<String>(
    //             value: selectedCategory,
    //             decoration: const InputDecoration(
    //               labelText: 'Category',
    //             ),
    //             items: [
    //               'food',
    //               'transport',
    //               'shopping',
    //               'utilities',
    //               'entertainment',
    //               'other'
    //             ].map((String category) {
    //               return DropdownMenuItem(
    //                 value: category,
    //                 child: Text(category.toUpperCase()),
    //               );
    //             }).toList(),
    //             onChanged: (String? value) {
    //               if (value != null) {
    //                 selectedCategory = value;
    //               }
    //             },
    //           ),
    //         ],
    //       ),
    //     ),
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.pop(context),
    //         child: const Text('Cancel'),
    //       ),
    //       FilledButton(
    //         onPressed: () {
    //           final double? amount = double.tryParse(amountController.text);
    //           if (amount != null) {
    //             Provider.of<ExpenseProvider>(context, listen: false)
    //                 .updateExpense(
    //               expense.id,
    //               descriptionController.text,
    //               amount,
    //               selectedCategory,
    //             );
    //             Navigator.pop(context);
    //           }
    //         },
    //         child: const Text('Save'),
    //       ),
    //     ],
    //   ),
    // );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍽️ Ăn uống';
      case 'transport':
        return '🚗 Giao thông';
      case 'utilities':
        return '⚡ Tiện ích';
      case 'health':
        return '🏥 Sức khỏe';
      case 'education':
        return '📚 Giáo dục';
      case 'shopping':
        return '🛍️ Mua sắm';
      case 'entertainment':
        return '🎬 Giải trí';
      default:
        return '📦 Khác';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'utilities':
        return Icons.power;
      case 'health':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.attach_money;
    }
  }
}
