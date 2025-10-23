import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spend_sage/providers/expense_provider.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:spend_sage/widgets/expense_chart.dart';
import 'package:spend_sage/widgets/category_chart.dart';
import 'package:spend_sage/widgets/chart_totals.dart';
import 'package:spend_sage/widgets/filter_selector.dart';
import 'package:spend_sage/widgets/advanced_analytics.dart';
import 'package:spend_sage/widgets/spending_insights.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedTab = 0;

  final List<String> _tabs = [
    'Tổng quan',
    'Phân tích',
    'Thông tin',
  ];

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
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, _) {
        final expenses = expenseProvider.expenses;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF667eea),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
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
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Phân tích chi tiêu',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hiểu rõ thói quen chi tiêu của bạn',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: const [
                  FilterSelector(),
                  SizedBox(width: 16),
                ],
              ),

              // Tab Bar
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: _tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      final isSelected = _selectedTab == index;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTab = index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF667eea).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tab,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF667eea)
                                    : Colors.grey.shade600,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildTabContent(expenses),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabContent(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return _buildEmptyState();
    }

    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab(expenses);
      case 1:
        return _buildAnalyticsTab(expenses);
      case 2:
        return _buildInsightsTab(expenses);
      default:
        return _buildOverviewTab(expenses);
    }
  }

  Widget _buildOverviewTab(List<Expense> expenses) {
    return Column(
      children: [
        // Expense Trend Chart
        ExpenseChart(expenses: expenses),
        const SizedBox(height: 20),

        // Category Distribution Chart
        CategoryChart(expenses: expenses),
        const SizedBox(height: 20),

        // Category Totals
        ChartTotals(expenses: expenses),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAnalyticsTab(List<Expense> expenses) {
    return Column(
      children: [
        // Advanced Analytics
        AdvancedAnalytics(expenses: expenses),
        const SizedBox(height: 20),

        // Category Totals
        ChartTotals(expenses: expenses),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInsightsTab(List<Expense> expenses) {
    return Column(
      children: [
        // Spending Insights
        SpendingInsights(expenses: expenses),
        const SizedBox(height: 20),

        // Category Chart
        CategoryChart(expenses: expenses),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 60,
              color: Color(0xFF667eea),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có dữ liệu phân tích',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hãy thêm một vài chi tiêu để xem phân tích chi tiết về thói quen chi tiêu của bạn.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to home screen to add expense
              DefaultTabController.of(context).animateTo(0);
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm chi tiêu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
