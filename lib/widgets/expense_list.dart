import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:spend_sage/utilities/utilities.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';

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

    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: expenses.map((expense) {
            return Dismissible(
              key: Key(expense.id),
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delete, color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      'Xóa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                // Show confirmation dialog instead of auto-dismiss
                _showDeleteConfirmation(context, expense);
                return false; // Don't auto-dismiss
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
                  '${settings.currency}${expense.amount.toStringAsFixed(2)}',
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
      },
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
              decoration: InputDecoration(
                labelText: 'Mô tả',
                labelStyle: const TextStyle(color: Colors.black87),
                hintText: 'Nhập mô tả chi tiêu...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon:
                    const Icon(Icons.description_outlined, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF667eea),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'Số tiền',
                labelStyle: const TextStyle(color: Colors.black87),
                hintText: 'Nhập số tiền...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.attach_money, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF667eea),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'Danh mục',
                labelStyle: const TextStyle(color: Colors.black87),
                prefixIcon:
                    const Icon(Icons.category_outlined, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF667eea),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              dropdownColor: Colors.white,
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
                  child: Text(
                    _getCategoryDisplayName(category),
                    style: const TextStyle(color: Colors.black),
                  ),
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
        // Delete button
        TextButton.icon(
          onPressed: () async {
            Navigator.pop(context); // Close edit dialog
            _showDeleteConfirmation(context, expense);
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Xóa'),
        ),
        const SizedBox(width: 8),
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Hủy'),
        ),
        const SizedBox(width: 8),
        // Save button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667eea),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã cập nhật chi tiêu thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
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
        return 'Ăn uống';
      case 'transport':
        return 'Giao thông';
      case 'utilities':
        return 'Tiện ích';
      case 'health':
        return 'Sức khỏe';
      case 'education':
        return 'Giáo dục';
      case 'shopping':
        return 'Mua sắm';
      case 'entertainment':
        return 'Giải trí';
      default:
        return 'Khác';
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

  void _showDeleteConfirmation(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa chi tiêu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn xóa chi tiêu này?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_getCategoryDisplayName(expense.category)} • ${_formatDate(expense.dateTime)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hành động này không thể hoàn tác.',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<ExpenseProvider>(context, listen: false)
                  .deleteExpense(expense.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('✅ Đã xóa chi tiêu thành công!'),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'Hoàn tác',
                      textColor: Colors.white,
                      onPressed: () {
                        // TODO: Implement undo functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng hoàn tác đang phát triển'),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
