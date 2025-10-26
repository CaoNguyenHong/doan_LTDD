import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart' as models;
import '../utils/currency_formatter.dart';
import 'transaction_edit_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'all';
  String _selectedPeriod = 'month';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> _filterOptions = {
    'all': 'Tất cả',
    'expense': 'Chi tiêu',
    'income': 'Thu nhập',
    'transfer': 'Chuyển khoản',
    'refund': 'Hoàn tiền',
  };

  final Map<String, String> _periodOptions = {
    'day': 'Ngày',
    'week': 'Tuần',
    'month': 'Tháng',
    'year': 'Năm',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Lịch sử giao dịch',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, SettingsProvider>(
        builder: (context, transactionProvider, settingsProvider, _) {
          final transactions =
              _getFilteredTransactions(transactionProvider.transactions);
          final groupedTransactions = _groupTransactionsByDate(transactions);

          return Column(
            children: [
              // Summary Cards
              _buildSummaryCards(transactions, settingsProvider),

              // Filter Chips
              _buildFilterChips(),

              // Transactions List
              Expanded(
                child: groupedTransactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionsList(
                        groupedTransactions, settingsProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(
      List<models.Transaction> transactions, SettingsProvider settings) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (final transaction in transactions) {
      switch (transaction.type) {
        case 'income':
          totalIncome += transaction.amount;
          break;
        case 'expense':
          totalExpense += transaction.amount;
          break;
        case 'transfer':
        case 'refund':
          // These are not shown in summary cards
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Thu nhập',
              totalIncome,
              Colors.green,
              Icons.trending_up,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Chi tiêu',
              totalExpense,
              Colors.red,
              Icons.trending_down,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final key = _filterOptions.keys.elementAt(index);
          final value = _filterOptions[key]!;
          final isSelected = _selectedFilter == key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(value),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = key;
                });
              },
              backgroundColor: Colors.white,
              selectedColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có giao dịch',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có giao dịch nào trong khoảng thời gian này',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
      Map<String, List<models.Transaction>> groupedTransactions,
      SettingsProvider settings) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final date = groupedTransactions.keys.elementAt(index);
        final transactions = groupedTransactions[date]!;

        return _buildDateGroup(date, transactions, settings);
      },
    );
  }

  Widget _buildDateGroup(String date, List<models.Transaction> transactions,
      SettingsProvider settings) {
    final dateTime = DateTime.parse(date);
    final dayOfWeek = _getDayOfWeek(dateTime.weekday);
    final monthYear = '${dateTime.month}/${dateTime.year}';

    // Calculate totals for this date
    double dayIncome = 0;
    double dayExpense = 0;

    for (final transaction in transactions) {
      switch (transaction.type) {
        case 'income':
          dayIncome += transaction.amount;
          break;
        case 'expense':
          dayExpense += transaction.amount;
          break;
        case 'transfer':
        case 'refund':
          // These are not shown in day totals
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Day number
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      dateTime.day.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Date info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayOfWeek,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        monthYear,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Day totals
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (dayIncome > 0)
                      Text(
                        '+${CurrencyFormatter.format(dayIncome)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    if (dayExpense > 0)
                      Text(
                        '-${CurrencyFormatter.format(dayExpense)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Transactions
          ...transactions.map(
              (transaction) => _buildTransactionItem(transaction, settings)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
      models.Transaction transaction, SettingsProvider settings) {
    final isExpense =
        transaction.type == 'expense' || transaction.type == 'transfer';
    final amountColor = _getTransactionColor(transaction.type);
    final categoryName = _getCategoryName(transaction.categoryId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Category Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getCategoryIcon(transaction.categoryId),
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (transaction.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(transaction.dateTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          GestureDetector(
            onTap: () => _showTransactionOptions(transaction),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${isExpense ? '-' : '+'}${CurrencyFormatter.format(transaction.amount, currency: settings.currency)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionOptions(models.Transaction transaction) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Chỉnh sửa',
                    style: TextStyle(color: Colors.blue)),
                onTap: () {
                  Navigator.pop(context);
                  _editTransaction(transaction);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteTransaction(transaction);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editTransaction(models.Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionEditSheet(transaction: transaction),
    );
  }

  void _confirmDeleteTransaction(models.Transaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
              'Bạn có chắc chắn muốn xóa giao dịch "${transaction.description.isNotEmpty ? transaction.description : _getCategoryName(transaction.categoryId)} - ${CurrencyFormatter.format(transaction.amount)}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                final transactionProvider =
                    Provider.of<TransactionProvider>(context, listen: false);
                try {
                  await transactionProvider.deleteTransaction(transaction.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Đã xóa giao dịch thành công!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi xóa giao dịch: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm kiếm giao dịch'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Nhập từ khóa tìm kiếm...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Period filter
            DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Khoảng thời gian',
                border: OutlineInputBorder(),
              ),
              items: _periodOptions.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            // Type filter
            DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: const InputDecoration(
                labelText: 'Loại giao dịch',
                border: OutlineInputBorder(),
              ),
              items: _filterOptions.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'all';
                _selectedPeriod = 'month';
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Đặt lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  List<models.Transaction> _getFilteredTransactions(
      List<models.Transaction> transactions) {
    List<models.Transaction> filtered = transactions;

    // Filter by type
    if (_selectedFilter != 'all') {
      filtered = filtered.where((t) => t.type == _selectedFilter).toList();
    }

    // Filter by period
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_selectedPeriod) {
      case 'day':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    filtered = filtered.where((t) {
      return t.dateTime.isAfter(startDate) && t.dateTime.isBefore(endDate);
    }).toList();

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            _getCategoryName(t.categoryId)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  Map<String, List<models.Transaction>> _groupTransactionsByDate(
      List<models.Transaction> transactions) {
    final Map<String, List<models.Transaction>> grouped = {};

    for (final transaction in transactions) {
      final dateKey = transaction.dateTime.toIso8601String().split('T')[0];
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    // Sort by date (newest first)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final Map<String, List<models.Transaction>> sortedGrouped = {};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  String _getDayOfWeek(int weekday) {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[weekday % 7];
  }

  String _getCategoryName(String? categoryId) {
    const categoryMap = {
      'food': '🍽️ Ăn uống',
      'transport': '🚗 Di chuyển',
      'shopping': '🛍️ Mua sắm',
      'entertainment': '🎬 Giải trí',
      'health': '🏥 Sức khỏe',
      'education': '📚 Giáo dục',
      'utilities': '💡 Tiện ích',
      'other': '📝 Khác',
      'salary': '💰 Lương',
      'freelance': '💼 Freelance',
      'investment': '📈 Đầu tư',
      'business': '🏢 Kinh doanh',
      'gift': '🎁 Quà tặng',
      'savings': '🏦 Tiết kiệm',
      'loan': '💳 Vay mượn',
      'family': '👨‍👩‍👧‍👦 Gia đình',
      'purchase': '🛒 Mua hàng',
      'service': '🔧 Dịch vụ',
      'subscription': '📱 Đăng ký',
    };
    return categoryMap[categoryId] ?? '📝 Khác';
  }

  IconData _getCategoryIcon(String? categoryId) {
    const iconMap = {
      'food': Icons.restaurant,
      'transport': Icons.directions_car,
      'shopping': Icons.shopping_bag,
      'entertainment': Icons.movie,
      'health': Icons.local_hospital,
      'education': Icons.school,
      'utilities': Icons.electrical_services,
      'other': Icons.category,
      'salary': Icons.work,
      'freelance': Icons.computer,
      'investment': Icons.trending_up,
      'business': Icons.business,
      'gift': Icons.card_giftcard,
      'savings': Icons.savings,
      'loan': Icons.account_balance,
      'family': Icons.family_restroom,
      'purchase': Icons.shopping_cart,
      'service': Icons.build,
      'subscription': Icons.subscriptions,
    };
    return iconMap[categoryId] ?? Icons.category;
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      case 'transfer':
        return Colors.blue;
      case 'refund':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
