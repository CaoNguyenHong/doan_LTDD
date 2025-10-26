import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart' as models;
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/transaction_converter.dart';

class TransactionEditSheet extends StatefulWidget {
  final models.Transaction transaction;

  const TransactionEditSheet({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  State<TransactionEditSheet> createState() => _TransactionEditSheetState();
}

class _TransactionEditSheetState extends State<TransactionEditSheet> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late String _selectedCategoryId;
  late String _selectedType;

  // Categories for different transaction types
  final Map<String, List<String>> _categoriesByType = {
    'expense': [
      'food',
      'transport',
      'entertainment',
      'shopping',
      'health',
      'education',
      'utilities',
      'other',
    ],
    'income': [
      'salary',
      'freelance',
      'investment',
      'business',
      'gift',
      'other',
    ],
    'transfer': [
      'savings',
      'investment',
      'loan',
      'family',
      'other',
    ],
    'refund': [
      'purchase',
      'service',
      'subscription',
      'other',
    ],
  };

  final List<String> _types = ['expense', 'income', 'transfer', 'refund'];

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.transaction.description);
    _amountController =
        TextEditingController(text: widget.transaction.amount.toString());
    _selectedType = widget.transaction.type;

    // Ensure the selected category is valid for the current type
    final availableCategories = _categoriesByType[_selectedType] ?? ['other'];
    final currentCategoryId = widget.transaction.categoryId ?? 'other';

    // Debug log
    print('🔍 EditSheet initState:');
    print('  - Transaction type: $_selectedType');
    print('  - Current categoryId: $currentCategoryId');
    print('  - Available categories: $availableCategories');

    if (availableCategories.contains(currentCategoryId)) {
      _selectedCategoryId = currentCategoryId;
    } else {
      _selectedCategoryId = availableCategories.first;
    }

    print('  - Selected categoryId: $_selectedCategoryId');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<String> _getCurrentCategories() {
    return _categoriesByType[_selectedType] ?? ['other'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Chỉnh sửa giao dịch',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Transaction Type
            const Text(
              'Loại giao dịch',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _types.map((type) {
                String label;
                switch (type) {
                  case 'expense':
                    label = 'Chi tiêu';
                    break;
                  case 'income':
                    label = 'Thu nhập';
                    break;
                  case 'transfer':
                    label = 'Chuyển khoản';
                    break;
                  case 'refund':
                    label = 'Hoàn tiền';
                    break;
                  default:
                    label = type;
                }
                return DropdownMenuItem(
                  value: type,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    // Reset category when type changes
                    final availableCategories = _categoriesByType[value] ?? [];
                    if (availableCategories.isNotEmpty) {
                      _selectedCategoryId = availableCategories.first;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Category
            const Text(
              'Danh mục',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _getCurrentCategories().map((categoryId) {
                final categoryName =
                    TransactionConverter.mapCategory(categoryId);
                return DropdownMenuItem(
                  value: categoryId,
                  child: Text(categoryName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Mô tả',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Nhập mô tả giao dịch',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            const Text(
              'Số tiền',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nhập số tiền',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixText:
                    Provider.of<SettingsProvider>(context, listen: false)
                        .currency,
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _saveTransaction() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mô tả'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final updatedTransaction = widget.transaction.copyWith(
        type: _selectedType,
        categoryId: _selectedCategoryId,
        description: _descriptionController.text.trim(),
        amount: amount,
        updatedAt: DateTime.now(),
      );

      await Provider.of<TransactionProvider>(context, listen: false)
          .updateTransaction(updatedTransaction);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật giao dịch thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
