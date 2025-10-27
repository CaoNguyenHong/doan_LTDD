import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';
import '../utils/currency_formatter.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  String? _selectedCategoryFilter; // null = "Toàn bộ"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ngân sách',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddBudgetDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, _) {
          if (budgetProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (budgetProvider.error?.isNotEmpty == true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${budgetProvider.error}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (budgetProvider.budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có ngân sách nào',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy tạo ngân sách đầu tiên của bạn',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddBudgetDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo ngân sách'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                _buildSummaryCard(context, budgetProvider),
                const SizedBox(height: 24),

                // Warning banners
                if (budgetProvider.hasOverBudget()) ...[
                  _buildWarningBanner(
                      context, 'Vượt quá ngân sách', Colors.red, Icons.warning),
                  const SizedBox(height: 16),
                ],
                if (budgetProvider.hasNearLimit()) ...[
                  _buildWarningBanner(context, 'Gần đạt giới hạn ngân sách',
                      Colors.orange, Icons.info),
                  const SizedBox(height: 16),
                ],

                // Budgets list
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Danh sách ngân sách',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    _buildCategoryFilter(),
                  ],
                ),
                const SizedBox(height: 16),

                ..._getFilteredBudgets(budgetProvider.budgets).map((budget) =>
                    _buildBudgetCard(context, budget, budgetProvider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, BudgetProvider budgetProvider) {
    final totalLimit = budgetProvider.getTotalBudgetLimit();
    final totalSpent = budgetProvider.getTotalBudgetSpent();
    final utilization = budgetProvider.getUtilizationPercentage();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Tổng quan ngân sách',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng ngân sách',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    Text(
                      CurrencyFormatter.format(totalLimit, currency: 'VND'),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đã chi',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    Text(
                      CurrencyFormatter.format(totalSpent, currency: 'VND'),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: utilization / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: utilization > 100
                      ? Colors.red
                      : utilization > 80
                          ? Colors.orange
                          : Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${utilization.toStringAsFixed(1)}% đã sử dụng',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(
      BuildContext context, String message, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
      BuildContext context, Budget budget, BudgetProvider budgetProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getBudgetColor(budget).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: _getBudgetColor(budget),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCategoryDisplayName(budget.categoryId),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        budget.periodDisplayName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBudgetColor(budget).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    budget.statusText,
                    style: TextStyle(
                      color: _getBudgetColor(budget),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã chi: ${CurrencyFormatter.format(budget.spent, currency: 'VND')}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Giới hạn: ${CurrencyFormatter.format(budget.limit, currency: 'VND')}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: budget.percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_getBudgetColor(budget)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${budget.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showEditBudgetDialog(context, budget, budgetProvider),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Chỉnh sửa'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteBudgetDialog(
                        context, budget, budgetProvider),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label:
                        const Text('Xóa', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBudgetColor(Budget budget) {
    if (budget.isWarning) return Colors.red;
    if (budget.isNearLimit) return Colors.orange;
    return Colors.green;
  }

  String _getCategoryDisplayName(String? categoryId) {
    if (categoryId == null) return 'Toàn bộ';

    switch (categoryId) {
      case 'food':
        return 'Ăn uống';
      case 'transport':
        return 'Giao thông';
      case 'entertainment':
        return 'Giải trí';
      case 'shopping':
        return 'Mua sắm';
      case 'health':
        return 'Sức khỏe';
      case 'education':
        return 'Giáo dục';
      case 'utilities':
        return 'Tiện ích';
      case 'other':
        return 'Khác';
      default:
        return categoryId;
    }
  }

  String _getPeriodIdentifier(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'daily':
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case 'weekly':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      case 'monthly':
        return '${now.year}-${now.month.toString().padLeft(2, '0')}';
      case 'yearly':
        return '${now.year}';
      default:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }
  }

  void _showAddBudgetDialog(BuildContext context) {
    final limitController = TextEditingController();
    String selectedPeriod = 'monthly';
    String? selectedCategory;

    // Calculate period identifier based on selected period
    String selectedMonth = _getPeriodIdentifier(selectedPeriod);

    // Get providers at the beginning
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Tạo ngân sách mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Chu kỳ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Hàng ngày')),
                    DropdownMenuItem(value: 'weekly', child: Text('Hàng tuần')),
                    DropdownMenuItem(
                        value: 'monthly', child: Text('Hàng tháng')),
                    DropdownMenuItem(value: 'yearly', child: Text('Hàng năm')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedPeriod = value!;
                      selectedMonth = _getPeriodIdentifier(selectedPeriod);
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: limitController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Giới hạn ngân sách (VND)',
                    border: OutlineInputBorder(),
                    prefixText: 'VND ',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toàn bộ')),
                    const DropdownMenuItem(
                        value: 'food', child: Text('Ăn uống')),
                    const DropdownMenuItem(
                        value: 'transport', child: Text('Giao thông')),
                    const DropdownMenuItem(
                        value: 'utilities', child: Text('Tiện ích')),
                    const DropdownMenuItem(
                        value: 'health', child: Text('Sức khỏe')),
                    const DropdownMenuItem(
                        value: 'education', child: Text('Giáo dục')),
                    const DropdownMenuItem(
                        value: 'shopping', child: Text('Mua sắm')),
                    const DropdownMenuItem(
                        value: 'entertainment', child: Text('Giải trí')),
                    const DropdownMenuItem(value: 'other', child: Text('Khác')),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedCategory = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (limitController.text.isNotEmpty) {
                  final budget = Budget(
                    id: const Uuid().v4(),
                    period: selectedPeriod,
                    month: selectedMonth,
                    categoryId: selectedCategory,
                    limit: double.tryParse(limitController.text) ?? 0.0,
                    spent: 0.0,
                    updatedAt: DateTime.now(),
                  );

                  await budgetProvider.addBudget(budget);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đã tạo ngân sách thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBudgetDialog(
      BuildContext context, Budget budget, BudgetProvider budgetProvider) {
    final limitController = TextEditingController(
        text: CurrencyFormatter.format(budget.limit, currency: 'VND')
            .replaceAll('VND', ''));
    String selectedPeriod = budget.period;
    String? selectedCategory = budget.categoryId;
    String selectedMonth = budget.month;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Chỉnh sửa ngân sách'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Chu kỳ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Hàng ngày')),
                    DropdownMenuItem(value: 'weekly', child: Text('Hàng tuần')),
                    DropdownMenuItem(
                        value: 'monthly', child: Text('Hàng tháng')),
                    DropdownMenuItem(value: 'yearly', child: Text('Hàng năm')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedPeriod = value!;
                      selectedMonth = _getPeriodIdentifier(selectedPeriod);
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: limitController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Giới hạn ngân sách (VND)',
                    border: OutlineInputBorder(),
                    prefixText: 'VND ',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toàn bộ')),
                    const DropdownMenuItem(
                        value: 'food', child: Text('Ăn uống')),
                    const DropdownMenuItem(
                        value: 'transport', child: Text('Giao thông')),
                    const DropdownMenuItem(
                        value: 'utilities', child: Text('Tiện ích')),
                    const DropdownMenuItem(
                        value: 'health', child: Text('Sức khỏe')),
                    const DropdownMenuItem(
                        value: 'education', child: Text('Giáo dục')),
                    const DropdownMenuItem(
                        value: 'shopping', child: Text('Mua sắm')),
                    const DropdownMenuItem(
                        value: 'entertainment', child: Text('Giải trí')),
                    const DropdownMenuItem(value: 'other', child: Text('Khác')),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedCategory = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (limitController.text.isNotEmpty) {
                  final updatedBudget = budget.copyWith(
                    period: selectedPeriod,
                    month: selectedMonth,
                    categoryId: selectedCategory,
                    limit:
                        double.tryParse(limitController.text) ?? budget.limit,
                    updatedAt: DateTime.now(),
                  );

                  await budgetProvider.updateBudget(updatedBudget);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đã cập nhật ngân sách thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteBudgetDialog(
      BuildContext context, Budget budget, BudgetProvider budgetProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa ngân sách'),
        content: Text('Bạn có chắc chắn muốn xóa ngân sách này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await budgetProvider.deleteBudget(budget.id);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã xóa ngân sách thành công!'),
                    backgroundColor: Colors.green,
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

  // Bộ lọc danh mục
  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedCategoryFilter,
          hint: const Text('Tất cả'),
          isDense: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Toàn bộ'),
            ),
            const DropdownMenuItem<String?>(
              value: 'food',
              child: Text('Ăn uống'),
            ),
            const DropdownMenuItem<String?>(
              value: 'transport',
              child: Text('Giao thông'),
            ),
            const DropdownMenuItem<String?>(
              value: 'entertainment',
              child: Text('Giải trí'),
            ),
            const DropdownMenuItem<String?>(
              value: 'shopping',
              child: Text('Mua sắm'),
            ),
            const DropdownMenuItem<String?>(
              value: 'health',
              child: Text('Sức khỏe'),
            ),
            const DropdownMenuItem<String?>(
              value: 'education',
              child: Text('Giáo dục'),
            ),
            const DropdownMenuItem<String?>(
              value: 'utilities',
              child: Text('Tiện ích'),
            ),
            const DropdownMenuItem<String?>(
              value: 'other',
              child: Text('Khác'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCategoryFilter = value;
            });
          },
        ),
      ),
    );
  }

  // Lọc ngân sách theo danh mục
  List<Budget> _getFilteredBudgets(List<Budget> budgets) {
    if (_selectedCategoryFilter == null) {
      // Hiển thị ngân sách "Toàn bộ" (categoryId = null)
      return budgets.where((budget) => budget.categoryId == null).toList();
    }
    return budgets
        .where((budget) => budget.categoryId == _selectedCategoryFilter)
        .toList();
  }
}
