import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:spend_sage/widgets/filter_selector.dart';
import 'package:spend_sage/widgets/spending_limit_widget.dart';
import '../providers/expense_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction.dart' as models;
import '../utils/currency_formatter.dart';
import 'transaction_add_sheet.dart';
import 'transaction_edit_sheet.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToCharts;

  const HomeScreen({super.key, this.onNavigateToCharts});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize();
  }

  void _showAddExpenseDialog(
      BuildContext context, ExpenseProvider expenseProvider) {
    _showTransactionAddSheet(context);
  }

  void _showTransactionAddSheet(BuildContext context) {
    // LẤY CÁC INSTANCE HIỆN CÓ TỪ CÂY WIDGET
    final accountProvider = context.read<AccountProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      useRootNavigator: false, // ❗ Giữ FALSE để sheet cùng scope Provider
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        // Truyền lại CHÍNH CÁC INSTANCE đang dùng bằng .value (không tạo mới)
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AccountProvider>.value(
                value: accountProvider),
            ChangeNotifierProvider<TransactionProvider>.value(
                value: transactionProvider),
            ChangeNotifierProvider<SettingsProvider>.value(
                value: settingsProvider),
          ],
          child:
              const TransactionAddSheet(), // Không truyền context/read<User> ở đây
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            title: const Text('SpendSage'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 0,
            actions: [
              // Realtime sync indicator
              Consumer3<ExpenseProvider, AnalyticsProvider,
                  NotificationProvider>(
                builder: (context, expenseProvider, analyticsProvider,
                    notificationProvider, _) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sync indicator
                        if (expenseProvider.isLoading ||
                            analyticsProvider.isLoading)
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.cloud_done,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        // Notification indicator
                        if (notificationProvider.hasNewNotifications)
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: Stack(
                              children: [
                                const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
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
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FilterSelector(),
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header

                  const SizedBox(height: 20),

                  // Spending Limit Widget
                  const SpendingLimitWidget(),

                  const SizedBox(height: 20),

                  // Quick Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thao tác nhanh',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                icon: Icons.add_circle_outline,
                                label: 'Thêm chi tiêu',
                                color: Theme.of(context).colorScheme.primary,
                                onTap: () => _showAddExpenseDialog(
                                    context, expenseProvider),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                icon: Icons.analytics_outlined,
                                label: 'Xem báo cáo',
                                color: Theme.of(context).colorScheme.secondary,
                                onTap: () {
                                  if (widget.onNavigateToCharts != null) {
                                    widget.onNavigateToCharts!();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Chuyển đến tab Biểu đồ'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Recent Transactions Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Giao dịch gần đây',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _showTransactionAddSheet(context),
                        child: Text(
                          'Thêm mới',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Transactions by Date
                  Consumer2<TransactionProvider, SettingsProvider>(
                    builder:
                        (context, transactionProvider, settingsProvider, _) {
                      if (transactionProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (transactionProvider.error?.isNotEmpty == true) {
                        return Center(
                            child: Text('Lỗi: ${transactionProvider.error}'));
                      }

                      final transactions = transactionProvider.transactions;

                      // Debug log để kiểm tra dữ liệu
                      // print(
                      //     '🔍 HomeScreen: Received ${transactions.length} transactions');
                      // for (final transaction in transactions) {
                      //   print(
                      //       '  - ${transaction.type}: ${transaction.amount} (${transaction.dateTime})');
                      // }

                      if (transactions.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 50),
                              Icon(
                                Icons.receipt_long,
                                size: 80,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Chưa có giao dịch nào được ghi nhận.',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Hãy thêm giao dịch đầu tiên của bạn!',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _showTransactionAddSheet(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm giao dịch'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Group transactions by date
                      final groupedTransactions =
                          _groupTransactionsByDate(transactions);
                      final sortedDates = groupedTransactions.keys.toList()
                        ..sort((a, b) => b.compareTo(a));

                      return Column(
                        children: sortedDates.map((date) {
                          final dayTransactions = groupedTransactions[date]!;
                          return _buildDateGroup(
                              date, dayTransactions, settingsProvider);
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 30,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<models.Transaction>> _groupTransactionsByDate(
      List<models.Transaction> transactions) {
    final Map<DateTime, List<models.Transaction>> grouped = {};

    for (final transaction in transactions) {
      final date = DateTime(
        transaction.dateTime.year,
        transaction.dateTime.month,
        transaction.dateTime.day,
      );

      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }

    return grouped;
  }

  Widget _buildDateGroup(DateTime date, List<models.Transaction> transactions,
      SettingsProvider settings) {
    // Calculate income and expense totals
    double incomeTotal = 0;
    double expenseTotal = 0;

    for (final transaction in transactions) {
      if (transaction.type == 'income' || transaction.type == 'refund') {
        incomeTotal += transaction.amount;
      } else if (transaction.type == 'expense') {
        expenseTotal += transaction.amount;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header - Large number style like Misa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Large day number
                Text(
                  '${date.day}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                // Date info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDayOfWeek(date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${date.month}/${date.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Income/Expense totals
                if (incomeTotal > 0 || expenseTotal > 0) ...[
                  if (incomeTotal > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        CurrencyFormatter.format(incomeTotal,
                            currency: settings.currency),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (expenseTotal > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        CurrencyFormatter.format(expenseTotal,
                            currency: settings.currency),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          // Transactions list with connecting line
          Container(
            margin: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                // Vertical connecting line
                Container(
                  width: 2,
                  height: 20,
                  color: Colors.grey.shade300,
                ),
                // Transactions
                ...transactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final transaction = entry.value;
                  final isLast = index == transactions.length - 1;

                  return Column(
                    children: [
                      _buildTransactionItem(transaction, settings),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.grey.shade300,
                        ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
      models.Transaction transaction, SettingsProvider settings) {
    final isExpense = transaction.type == 'expense';
    final isTransfer = transaction.type == 'transfer';
    final isRefund = transaction.type == 'refund';

    Color amountColor;
    String categoryIcon;
    String categoryName;

    if (isExpense) {
      amountColor = Colors.red;
      categoryIcon = '🍽️';
      categoryName = _getCategoryName(transaction.categoryId);
    } else if (transaction.type == 'income') {
      amountColor = Colors.green;
      categoryIcon = '💰';
      categoryName = 'Lương';
    } else if (isTransfer) {
      amountColor = Colors.blue;
      categoryIcon = '🔄';
      categoryName = 'Chuyển khoản';
    } else if (isRefund) {
      amountColor = Colors.orange;
      categoryIcon = '↩️';
      categoryName = 'Hoàn tiền';
    } else {
      amountColor = Colors.grey;
      categoryIcon = '📝';
      categoryName = 'Khác';
    }

    return GestureDetector(
      onTap: () => _showTransactionOptions(transaction),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  categoryIcon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Transaction details
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
                  const SizedBox(height: 4),
                  // Description
                  if (transaction.description.isNotEmpty) ...[
                    Text(
                      transaction.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ví',
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
            Text(
              '${isExpense || isTransfer ? '-' : '+'}${CurrencyFormatter.format(transaction.amount, currency: settings.currency)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            // Options button
            IconButton(
              onPressed: () => _showTransactionOptions(transaction),
              icon: Icon(
                Icons.more_vert,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    const days = [
      'Chủ nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy'
    ];
    return days[date.weekday % 7];
  }

  String _getCategoryName(String? categoryId) {
    switch (categoryId) {
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
      case 'other':
      default:
        return 'Khác';
    }
  }

  void _showTransactionOptions(models.Transaction transaction) {
    // print(
    //     '🔍 _showTransactionOptions called for transaction: ${transaction.id}');
    final settingsProvider = context.read<SettingsProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    // print('🔍 SettingsProvider obtained: ${settingsProvider.currency}');
    // print(
    //     '🔍 TransactionProvider obtained: ${transactionProvider.transactions.length} transactions');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Transaction info
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getTransactionColor(transaction.type)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        _getTransactionIcon(transaction.type),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryName(transaction.categoryId),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(transaction.amount,
                              currency: settingsProvider.currency),
                          style: TextStyle(
                            fontSize: 16,
                            color: _getTransactionColor(transaction.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${transaction.dateTime.day}/${transaction.dateTime.month}/${transaction.dateTime.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Action buttons
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                // print(
                //     '🔍 Edit button tapped for transaction: ${transaction.id}');
                Navigator.pop(context);
                _editTransaction(transaction, settingsProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa'),
              onTap: () {
                // print(
                //     '🔍 Delete button tapped for transaction: ${transaction.id}');
                Navigator.pop(context);
                _deleteTransaction(
                    transaction, settingsProvider, transactionProvider);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'expense':
        return Colors.red;
      case 'income':
        return Colors.green;
      case 'transfer':
        return Colors.blue;
      case 'refund':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTransactionIcon(String type) {
    switch (type) {
      case 'expense':
        return '🍽️';
      case 'income':
        return '💰';
      case 'transfer':
        return '🔄';
      case 'refund':
        return '↩️';
      default:
        return '📝';
    }
  }

  void _editTransaction(
      models.Transaction transaction, SettingsProvider settingsProvider) {
    // print('🔍 _editTransaction called for transaction: ${transaction.id}');
    // print('🔍 SettingsProvider currency: ${settingsProvider.currency}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionEditSheet(
        transaction: transaction,
        settingsProvider: settingsProvider,
      ),
    );
  }

  void _deleteTransaction(
      models.Transaction transaction,
      SettingsProvider settingsProvider,
      TransactionProvider transactionProvider) {
    // print('🔍 _deleteTransaction called for transaction: ${transaction.id}');
    // print('🔍 SettingsProvider currency: ${settingsProvider.currency}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa giao dịch này?\n\n${_getCategoryName(transaction.categoryId)} - ${CurrencyFormatter.format(transaction.amount, currency: settingsProvider.currency)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await transactionProvider.deleteTransaction(transaction.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa giao dịch thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi xóa: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
