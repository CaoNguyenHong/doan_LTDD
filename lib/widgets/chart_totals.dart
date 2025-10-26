import 'package:flutter/material.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/currency_formatter.dart';

class ChartTotals extends StatefulWidget {
  final List<Expense> expenses;

  const ChartTotals({super.key, required this.expenses});

  @override
  State<ChartTotals> createState() => _ChartTotalsState();
}

class _ChartTotalsState extends State<ChartTotals>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _sortBy = 'amount'; // 'amount' or 'name'

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final categoryTotals = _calculateCategoryTotals();
        final total =
            categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
        final currency = settings.currency;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          isDense: true,
          items: const [
            DropdownMenuItem(
              value: 'amount',
              child: Text('Theo số tiền'),
            ),
            DropdownMenuItem(
              value: 'name',
              child: Text('Theo tên'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _sortBy = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSummary(double total, int categoryCount, String currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF667eea).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng kết',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF667eea),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${CurrencyFormatter.format(total)} • $categoryCount danh mục',
                  style: TextStyle(
                    color: const Color(0xFF667eea),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.trending_up,
            color: const Color(0xFF667eea),
            size: 20,
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateCategoryTotals() {
    final Map<String, double> totals = {};
    for (var expense in widget.expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    // Sort based on selected criteria
    final entries = totals.entries.toList();
    switch (_sortBy) {
      case 'amount':
        entries.sort((a, b) => b.value.compareTo(a.value));
        break;
      case 'name':
        entries.sort((a, b) => a.key.compareTo(b.key));
        break;
    }

    return Map.fromEntries(entries);
  }

  int _getCategoryCount(String category) {
    return widget.expenses
        .where((expense) => expense.category == category)
        .length;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'utilities':
        return Colors.purple;
      case 'health':
        return Colors.red;
      case 'education':
        return Colors.green;
      case 'shopping':
        return Colors.pink;
      case 'entertainment':
        return Colors.teal;
      default:
        return Colors.grey;
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
}
