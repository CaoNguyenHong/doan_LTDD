import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart' as models;
import '../hive/expense.dart';
import '../utils/currency_formatter.dart';
import '../utils/transaction_converter.dart';
import '../widgets/expense_chart.dart';
import '../widgets/category_chart.dart';
import '../widgets/chart_totals.dart';
import '../widgets/filter_selector.dart';
import '../widgets/comprehensive_analytics.dart';

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

  // Global date filter state
  String _selectedPeriod = 'daily'; // daily, weekly, monthly
  DateTime? _selectedDate;
  DateTime? _selectedWeekStart;
  DateTime? _selectedMonthStart;

  // Transaction type filter
  String _selectedTransactionType =
      'expense'; // expense, income, transfer, refund, all

  final List<String> _tabs = [
    'Tổng quan',
    'Phân tích',
  ];

  @override
  void initState() {
    super.initState();

    // Set default values
    final now = DateTime.now();
    _selectedDate = now; // Default to today
    _selectedWeekStart = _getStartOfWeek(now); // Default to current week
    _selectedMonthStart =
        DateTime(now.year, now.month, 1); // Default to current month

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
    return Consumer2<TransactionProvider, SettingsProvider>(
      builder: (context, transactionProvider, settingsProvider, _) {
        final transactions = transactionProvider.transactions;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 100,
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
                  child: Column(
                    children: [
                      // Tab buttons
                      Row(
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                      // Date range selector
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Date range selector
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Color(0xFF667eea), size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Lọc theo:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateRangeSelector(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Transaction type selector
                            Row(
                              children: [
                                const Icon(Icons.category,
                                    color: Color(0xFF667eea), size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Loại giao dịch:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTransactionTypeSelector(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      child: _buildTabContent(transactions, settingsProvider),
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

  Widget _buildTabContent(List<models.Transaction> transactions,
      SettingsProvider settingsProvider) {
    // Apply date filter to transactions
    final filteredTransactions = _filterTransactionsByDateRange(transactions);

    if (filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab(filteredTransactions, settingsProvider);
      case 1:
        // Truyền toàn bộ transactions cho ComprehensiveAnalytics để có đủ dữ liệu cho cả 2 kỳ
        return _buildAnalyticsTab(transactions, settingsProvider);
      default:
        return _buildOverviewTab(filteredTransactions, settingsProvider);
    }
  }

  Widget _buildDateRangeSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Period selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              dropdownColor: Colors.white,
              style: const TextStyle(
                  color: Color(0xFF667eea),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Ngày')),
                DropdownMenuItem(value: 'weekly', child: Text('Tuần')),
                DropdownMenuItem(value: 'monthly', child: Text('Tháng')),
                DropdownMenuItem(value: 'yearly', child: Text('Năm')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriod = value;
                    // Set default values when period changes
                    final now = DateTime.now();
                    switch (value) {
                      case 'daily':
                        _selectedDate = now;
                        _selectedWeekStart = null;
                        _selectedMonthStart = null;
                        break;
                      case 'weekly':
                        _selectedDate = null;
                        _selectedWeekStart = _getStartOfWeek(now);
                        _selectedMonthStart = null;
                        break;
                      case 'monthly':
                        _selectedDate = null;
                        _selectedWeekStart = null;
                        _selectedMonthStart = DateTime(now.year, now.month, 1);
                        break;
                      case 'yearly':
                        _selectedDate = null;
                        _selectedWeekStart = null;
                        _selectedMonthStart = DateTime(now.year, 1, 1);
                        break;
                    }
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Date picker button
        GestureDetector(
          onTap: _showDatePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today,
                    color: Color(0xFF667eea), size: 16),
                const SizedBox(width: 4),
                Text(
                  _getPeriodDisplayName(),
                  style: const TextStyle(
                      color: Color(0xFF667eea),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF667eea).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTransactionType,
          dropdownColor: Colors.white,
          style: const TextStyle(
              color: Color(0xFF667eea),
              fontSize: 12,
              fontWeight: FontWeight.w600),
          items: const [
            DropdownMenuItem(value: 'expense', child: Text('Chi tiêu')),
            DropdownMenuItem(value: 'income', child: Text('Thu nhập')),
            DropdownMenuItem(value: 'transfer', child: Text('Chuyển khoản')),
            DropdownMenuItem(value: 'refund', child: Text('Hoàn tiền')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedTransactionType = value;
              });
            }
          },
        ),
      ),
    );
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Get Monday of the week (weekday 1)
    int daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  String _getPeriodDisplayName() {
    final now = DateTime.now();

    if (_selectedPeriod == 'daily') {
      if (_selectedDate != null) {
        return '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
      } else {
        return '${now.day}/${now.month}/${now.year}';
      }
    } else if (_selectedPeriod == 'weekly') {
      if (_selectedWeekStart != null) {
        return 'Tuần ${_selectedWeekStart!.day}/${_selectedWeekStart!.month}';
      } else {
        final weekStart = _getStartOfWeek(now);
        return 'Tuần ${weekStart.day}/${weekStart.month}';
      }
    } else if (_selectedPeriod == 'monthly') {
      if (_selectedMonthStart != null) {
        return '${_selectedMonthStart!.month}/${_selectedMonthStart!.year}';
      } else {
        return '${now.month}/${now.year}';
      }
    } else if (_selectedPeriod == 'yearly') {
      if (_selectedMonthStart != null) {
        return 'Năm ${_selectedMonthStart!.year}';
      } else {
        return 'Năm ${now.year}';
      }
    }
    return 'Chọn ngày';
  }

  Future<void> _showDatePicker() async {
    DateTime? selectedDate;

    if (_selectedPeriod == 'daily') {
      selectedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (selectedDate != null) {
        setState(() {
          _selectedDate = selectedDate;
        });
      }
    } else if (_selectedPeriod == 'weekly') {
      selectedDate = await showDatePicker(
        context: context,
        initialDate: _selectedWeekStart ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (selectedDate != null) {
        // Find Monday of the selected week
        final monday =
            selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        setState(() {
          _selectedWeekStart = monday;
        });
      }
    } else if (_selectedPeriod == 'monthly') {
      selectedDate = await showDatePicker(
        context: context,
        initialDate: _selectedMonthStart ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (selectedDate != null) {
        // First day of the selected month
        final firstDay = DateTime(selectedDate.year, selectedDate.month, 1);
        setState(() {
          _selectedMonthStart = firstDay;
        });
      }
    } else if (_selectedPeriod == 'yearly') {
      selectedDate = await showDatePicker(
        context: context,
        initialDate: _selectedMonthStart ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (selectedDate != null) {
        // First day of the selected year
        final firstDay = DateTime(selectedDate.year, 1, 1);
        setState(() {
          _selectedMonthStart = firstDay;
        });
      }
    }
  }

  List<Expense> _convertTransactionsToExpenses(
      List<models.Transaction> transactions) {
    // Filter transactions by selected type
    final filteredTransactions =
        transactions.where((t) => t.type == _selectedTransactionType).toList();

    // Convert to expenses (all transaction types can be converted to expenses for chart display)
    final expenses = filteredTransactions
        .map((transaction) =>
            TransactionConverter.transactionToExpense(transaction))
        .toList();

    return expenses;
  }

  List<models.Transaction> _filterTransactionsByDateRange(
      List<models.Transaction> transactions) {
    final now = DateTime.now();

    if (_selectedPeriod == 'daily') {
      final selectedDate = _selectedDate ?? now;
      final startOfDay =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      return transactions.where((t) {
        return t.dateTime.isAfter(startOfDay) && t.dateTime.isBefore(endOfDay);
      }).toList();
    } else if (_selectedPeriod == 'weekly') {
      final weekStart = _selectedWeekStart ?? _getStartOfWeek(now);
      final endOfWeek = weekStart.add(const Duration(days: 7));
      return transactions.where((t) {
        return t.dateTime.isAfter(weekStart) && t.dateTime.isBefore(endOfWeek);
      }).toList();
    } else if (_selectedPeriod == 'monthly') {
      final monthStart =
          _selectedMonthStart ?? DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(monthStart.year, monthStart.month + 1, 1);
      return transactions.where((t) {
        return t.dateTime.isAfter(monthStart) &&
            t.dateTime.isBefore(endOfMonth);
      }).toList();
    } else if (_selectedPeriod == 'yearly') {
      final yearStart = _selectedMonthStart ?? DateTime(now.year, 1, 1);
      final endOfYear = DateTime(yearStart.year + 1, 1, 1);
      return transactions.where((t) {
        return t.dateTime.isAfter(yearStart) && t.dateTime.isBefore(endOfYear);
      }).toList();
    }
    return transactions;
  }

  Widget _buildOverviewTab(List<models.Transaction> transactions,
      SettingsProvider settingsProvider) {
    // Lọc chỉ chi tiêu (expenses) cho biểu đồ
    final expenses = _convertTransactionsToExpenses(transactions);

    return Column(
      children: [
        // Tổng quan tài chính
        _buildFinancialSummary(transactions, settingsProvider),
        const SizedBox(height: 20),

        // Expense Trend Chart
        if (expenses.isNotEmpty) ...[
          ExpenseChart(expenses: expenses, period: _selectedPeriod),
          const SizedBox(height: 20),
        ],

        // Category Distribution Chart
        if (expenses.isNotEmpty) ...[
          CategoryChart(expenses: expenses),
          const SizedBox(height: 20),
        ],

        // Category Totals
        if (expenses.isNotEmpty) ...[
          ChartTotals(expenses: expenses),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildAnalyticsTab(List<models.Transaction> transactions,
      SettingsProvider settingsProvider) {
    print(
        '🔍 DEBUG ChartsScreen: Passing ${transactions.length} transactions to ComprehensiveAnalytics');
    print('  selectedPeriod: $_selectedPeriod');
    print('  selectedTransactionType: $_selectedTransactionType');
    print('  selectedDate: $_selectedDate');
    print('  selectedWeekStart: $_selectedWeekStart');
    print('  selectedMonthStart: $_selectedMonthStart');

    return ComprehensiveAnalytics(
      transactions: transactions,
      selectedPeriod: _selectedPeriod,
      selectedTransactionType: _selectedTransactionType,
      selectedDate: _selectedDate,
      selectedWeekStart: _selectedWeekStart,
      selectedMonthStart: _selectedMonthStart,
    );
  }

  Widget _buildFinancialSummary(List<models.Transaction> transactions,
      SettingsProvider settingsProvider) {
    // Tính toán tổng thu nhập, chi tiêu, chuyển khoản, hoàn tiền
    double totalIncome = 0;
    double totalExpense = 0;
    double totalTransfer = 0;
    double totalRefund = 0;

    for (final transaction in transactions) {
      switch (transaction.type) {
        case 'income':
          totalIncome += transaction.amount;
          break;
        case 'expense':
          totalExpense += transaction.amount;
          break;
        case 'transfer':
          totalTransfer += transaction.amount;
          break;
        case 'refund':
          totalRefund += transaction.amount;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan tài chính',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
          ),
          const SizedBox(height: 16),

          // Thu nhập
          _buildSummaryRow(
            'Thu nhập',
            totalIncome,
            Colors.green,
            Icons.trending_up,
          ),
          const SizedBox(height: 12),

          // Chi tiêu
          _buildSummaryRow(
            'Chi tiêu',
            totalExpense,
            Colors.red,
            Icons.trending_down,
          ),
          const SizedBox(height: 12),

          // Chuyển khoản
          _buildSummaryRow(
            'Chuyển khoản',
            totalTransfer,
            Colors.blue,
            Icons.swap_horiz,
          ),
          const SizedBox(height: 12),

          // Hoàn tiền
          _buildSummaryRow(
            'Hoàn tiền',
            totalRefund,
            Colors.orange,
            Icons.reply,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      String label, double amount, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2D3748),
                  ),
            ),
          ],
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
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
