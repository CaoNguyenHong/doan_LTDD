import 'package:flutter/material.dart';
import 'package:spend_sage/hive/expense.dart';

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
  String _sortBy = 'amount';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
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
    final categoryTotals = _calculateCategoryTotals();
    final total =
        categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng kết theo danh mục',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D3748),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng: \$${total.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildSortSelector(),
              ],
            ),
            const SizedBox(height: 24),

            // Category List
            SizedBox(
              height: 300,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ListView.builder(
                    itemCount: categoryTotals.length,
                    itemBuilder: (context, index) {
                      if (index >= categoryTotals.length)
                        return const SizedBox.shrink();
                      final entry = categoryTotals.entries.elementAt(index);
                      final percentage =
                          total > 0 ? (entry.value / total * 100) : 0.0;
                      final color = _getCategoryColor(entry.key);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Category Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getCategoryIcon(entry.key),
                                color: color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Category Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getCategoryDisplayName(entry.key),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}% • ${_getCategoryCount(entry.key)} giao dịch',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Amount and Progress
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${entry.value.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 80,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: percentage / 100,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Summary
            const SizedBox(height: 20),
            _buildSummary(total, categoryTotals.length),
          ],
        ),
      ),
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
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            DropdownMenuItem(value: 'amount', child: Text('Số tiền')),
            DropdownMenuItem(value: 'count', child: Text('Số lượng')),
            DropdownMenuItem(value: 'name', child: Text('Tên')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _sortBy = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummary(double total, int categoryCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea).withOpacity(0.1),
            const Color(0xFF764ba2).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.summarize,
              color: Color(0xFF667eea),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng kết',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${total.toStringAsFixed(2)} • $categoryCount danh mục',
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
      case 'count':
        entries.sort((a, b) =>
            _getCategoryCount(b.key).compareTo(_getCategoryCount(a.key)));
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
        return const Color(0xFF667eea);
      case 'transport':
        return const Color(0xFF48BB78);
      case 'shopping':
        return const Color(0xFFED8936);
      case 'utilities':
        return const Color(0xFFE53E3E);
      case 'entertainment':
        return const Color(0xFF9F7AEA);
      default:
        return const Color(0xFF38B2AC);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'utilities':
        return Icons.power;
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
      case 'shopping':
        return 'Mua sắm';
      case 'utilities':
        return 'Tiện ích';
      case 'entertainment':
        return 'Giải trí';
      default:
        return 'Khác';
    }
  }
}
