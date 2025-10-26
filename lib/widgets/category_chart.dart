import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spend_sage/hive/expense.dart';
import '../utils/transaction_converter.dart';

class CategoryChart extends StatefulWidget {
  final List<Expense> expenses;

  const CategoryChart({super.key, required this.expenses});

  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? _touchedIndex;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = _calculateCategoryData();
    final total = categoryData.values.fold(0.0, (sum, amount) => sum + amount);

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
                        'Phân bổ theo danh mục',
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
                if (_selectedCategory != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_selectedCategory!)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getCategoryColor(_selectedCategory!),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      TransactionConverter.mapCategory(_selectedCategory!),
                      style: TextStyle(
                        color: _getCategoryColor(_selectedCategory!),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Chart
            SizedBox(
              height: 300,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 60,
                    sections: _createPieSections(categoryData),
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (response?.touchedSection != null) {
                          final touchedIndex =
                              response!.touchedSection!.touchedSectionIndex;
                          if (touchedIndex >= 0 &&
                              touchedIndex < categoryData.length) {
                            setState(() {
                              _touchedIndex = touchedIndex;
                              _selectedCategory =
                                  categoryData.keys.elementAt(touchedIndex);
                            });
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Legend
            const SizedBox(height: 20),
            _buildLegend(categoryData, total),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, double> categoryData, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết danh mục',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...categoryData.entries.map((entry) {
            final percentage = (entry.value / total * 100);
            final isSelected = _selectedCategory == entry.key;
            final color = _getCategoryColor(entry.key);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? Border.all(color: color, width: 1) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TransactionConverter.mapCategory(entry.key),
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? color : Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}% • \$${entry.value.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: color,
                      size: 16,
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Map<String, double> _calculateCategoryData() {
    final Map<String, double> categoryTotals = {};
    for (var expense in widget.expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return Map.fromEntries(categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)));
  }

  List<PieChartSectionData> _createPieSections(
      Map<String, double> categoryData) {
    final total = categoryData.values.fold(0.0, (sum, amount) => sum + amount);
    final colors = _getCategoryColors();

    return categoryData.entries.map((entry) {
      final index = categoryData.keys.toList().indexOf(entry.key);
      final percentage = (entry.value / total) * 100;
      final color = colors[index % colors.length];
      final isTouched = index == _touchedIndex;

      return PieChartSectionData(
        color: isTouched ? color.withOpacity(0.8) : color,
        value: entry.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 120 : 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        badgeWidget: percentage > 10
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getCategoryIcon(entry.key),
                  size: 16,
                  color: color,
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  List<Color> _getCategoryColors() {
    return [
      const Color(0xFF667eea),
      const Color(0xFF48BB78),
      const Color(0xFFED8936),
      const Color(0xFFE53E3E),
      const Color(0xFF9F7AEA),
      const Color(0xFF38B2AC),
      const Color(0xFFF6AD55),
      const Color(0xFFFC8181),
    ];
  }

  Color _getCategoryColor(String category) {
    final colors = _getCategoryColors();
    final index = [
      'food',
      'transport',
      'shopping',
      'utilities',
      'entertainment',
      'other'
    ].indexOf(category.toLowerCase());
    return colors[index >= 0 ? index : 0];
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
}
