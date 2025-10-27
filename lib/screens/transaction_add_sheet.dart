import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/transaction_converter.dart';

class TransactionAddSheet extends StatefulWidget {
  const TransactionAddSheet({super.key});

  @override
  State<TransactionAddSheet> createState() => _TransactionAddSheetState();
}

class _TransactionAddSheetState extends State<TransactionAddSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _expenseFormKey = GlobalKey<FormState>();
  final _incomeFormKey = GlobalKey<FormState>();
  final _transferFormKey = GlobalKey<FormState>();
  final _refundFormKey = GlobalKey<FormState>();

  // Controllers
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  // Form data
  String _selectedType = 'expense';
  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId = 'food'; // Default to food category
  DateTime _selectedDate = DateTime.now();
  List<String> _tags = [];

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize with valid category for expense type
    final availableCategories = _categoriesByType[_selectedType] ?? ['other'];
    _selectedCategoryId = availableCategories.first;

    _tabController.addListener(() {
      setState(() {
        _selectedType = _getTypeFromTab(_tabController.index);
        print('🔍 DEBUG: Tab changed to index ${_tabController.index}, _selectedType: $_selectedType');
        // Reset category when type changes
        final availableCategories =
            _categoriesByType[_selectedType] ?? ['other'];
        if (availableCategories.isNotEmpty) {
          _selectedCategoryId = availableCategories.first;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  String _getTypeFromTab(int index) {
    switch (index) {
      case 0:
        return 'expense';
      case 1:
        return 'income';
      case 2:
        return 'transfer';
      case 3:
        return 'refund';
      default:
        return 'expense';
    }
  }

  List<String> _getCurrentCategories() {
    return _categoriesByType[_selectedType] ?? ['other'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Thêm giao dịch',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Chi tiêu', icon: Icon(Icons.remove_circle_outline)),
              Tab(text: 'Thu nhập', icon: Icon(Icons.add_circle_outline)),
              Tab(text: 'Chuyển khoản', icon: Icon(Icons.swap_horiz)),
              Tab(text: 'Hoàn tiền', icon: Icon(Icons.reply)),
            ],
          ),

          // Form content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpenseForm(),
                _buildIncomeForm(),
                _buildTransferForm(),
                _buildRefundForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseForm() {
    return _buildForm(
      title: 'Thêm chi tiêu',
      icon: Icons.remove_circle_outline,
      color: Colors.red,
      accounts: context.watch<AccountProvider>().accounts,
      formKey: _expenseFormKey,
    );
  }

  Widget _buildIncomeForm() {
    return _buildForm(
      title: 'Thêm thu nhập',
      icon: Icons.add_circle_outline,
      color: Colors.green,
      accounts: context.watch<AccountProvider>().accounts,
      formKey: _incomeFormKey,
    );
  }

  Widget _buildTransferForm() {
    return _buildForm(
      title: 'Chuyển khoản',
      icon: Icons.swap_horiz,
      color: Colors.blue,
      accounts: context.watch<AccountProvider>().accounts,
      formKey: _transferFormKey,
      showToAccount: true,
    );
  }

  Widget _buildRefundForm() {
    return _buildForm(
      title: 'Hoàn tiền',
      icon: Icons.reply,
      color: Colors.orange,
      accounts: context.watch<AccountProvider>().accounts,
      formKey: _refundFormKey,
    );
  }

  Widget _buildForm({
    required String title,
    required IconData icon,
    required Color color,
    required List accounts,
    required GlobalKey<FormState> formKey,
    bool showToAccount = false,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Số tiền',
                prefixIcon: Icon(Icons.attach_money, color: color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số tiền';
                }
                if (double.tryParse(value) == null) {
                  return 'Số tiền không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // From account
            DropdownButtonFormField<String>(
              value: accounts.any((account) => account.id == _selectedAccountId)
                  ? _selectedAccountId
                  : null,
              decoration: InputDecoration(
                labelText: 'Từ ví',
                prefixIcon: Icon(Icons.account_balance_wallet, color: color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: accounts.map<DropdownMenuItem<String>>((account) {
                return DropdownMenuItem(
                  value: account.id,
                  child: Row(
                    children: [
                      Text(account.typeIcon),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(account.name),
                      ),
                      Text(
                        '${account.balance.toStringAsFixed(0)} ${account.currency}',
                        style: TextStyle(
                          color:
                              account.balance < 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedAccountId = value),
              validator: (value) {
                if (value == null) return 'Vui lòng chọn ví';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Show current balance for selected account
            if (_selectedAccountId != null) ...[
              Consumer<AccountProvider>(
                builder: (context, accountProvider, child) {
                  final selectedAccount = accountProvider.items.firstWhere(
                    (account) => account.id == _selectedAccountId,
                    orElse: () => throw Exception('Account not found'),
                  );
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedAccount.balance < 0
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedAccount.balance < 0
                            ? Colors.red.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedAccount.balance < 0
                              ? Icons.warning
                              : Icons.account_balance_wallet,
                          color: selectedAccount.balance < 0
                              ? Colors.red
                              : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Số dư hiện tại: ${selectedAccount.balance.toStringAsFixed(0)} ${selectedAccount.currency}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedAccount.balance < 0
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // To account (for transfers)
            if (showToAccount) ...[
              DropdownButtonFormField<String>(
                value: accounts
                        .any((account) => account.id == _selectedToAccountId)
                    ? _selectedToAccountId
                    : null,
                decoration: InputDecoration(
                  labelText: 'Đến ví',
                  prefixIcon: Icon(Icons.account_balance, color: color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: accounts
                    .where((account) => account.id != _selectedAccountId)
                    .map<DropdownMenuItem<String>>((account) {
                  return DropdownMenuItem(
                    value: account.id,
                    child: Row(
                      children: [
                        Text(account.typeIcon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(account.name),
                        ),
                        Text(
                          '${account.balance.toStringAsFixed(0)} ${account.currency}',
                          style: TextStyle(
                            color:
                                account.balance < 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedToAccountId = value),
                validator: (value) {
                  if (value == null) return 'Vui lòng chọn ví đích';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Category (for expense/income/refund)
            if (!showToAccount) ...[
              DropdownButtonFormField<String>(
                value: _getCurrentCategories().contains(_selectedCategoryId)
                    ? _selectedCategoryId
                    : null,
                decoration: InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.category, color: color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _getCurrentCategories().map((categoryId) {
                  final categoryName =
                      TransactionConverter.mapCategory(categoryId);
                  return DropdownMenuItem(
                    value: categoryId,
                    child: Text(categoryName),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategoryId = value),
                validator: (value) {
                  if (value == null) return 'Vui lòng chọn danh mục';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                prefixIcon: Icon(Icons.description, color: color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mô tả';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: () async {
                // print(
                //     '🔍 Date picker tapped - current _selectedDate: $_selectedDate');
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime
                      .now(), // Chỉ cho phép chọn ngày hiện tại và quá khứ
                );
                // print('🔍 Date picker returned: $date');
                if (date != null) {
                  // print('🔍 Date picker selected: $date');
                  // print(
                  //     '🔍 Date picker formatted: ${date.day}/${date.month}/${date.year}');
                  // print('🔍 Before setState - _selectedDate: $_selectedDate');
                  setState(() {
                    _selectedDate = date;
                    // print('🔍 After setState - _selectedDate: $_selectedDate');
                  });
                } else {
                  // print('🔍 Date picker cancelled');
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Ngày',
                  prefixIcon: Icon(Icons.calendar_today, color: color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    print(
                        '🔍 Building date display - _selectedDate: $_selectedDate');
                    return Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Tags (phân cách bằng dấu phẩy)',
                prefixIcon: Icon(Icons.tag, color: color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                _tags = value
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
              },
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitTransaction(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon),
                    const SizedBox(width: 8),
                    Text('Thêm ${title.toLowerCase()}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTransaction() async {
    // Get the correct form key based on current tab
    GlobalKey<FormState> currentFormKey;
    switch (_tabController.index) {
      case 0:
        currentFormKey = _expenseFormKey;
        break;
      case 1:
        currentFormKey = _incomeFormKey;
        break;
      case 2:
        currentFormKey = _transferFormKey;
        break;
      case 3:
        currentFormKey = _refundFormKey;
        break;
      default:
        currentFormKey = _expenseFormKey;
    }

    if (!currentFormKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text;

    // Get providers
    final accountProvider =
        Provider.of<AccountProvider>(context, listen: false);
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    // Get currency from settings
    final currency = settingsProvider.currency;

    // Get current transaction type from tab index
    final currentType = _getTypeFromTab(_tabController.index);
    
    print('🔍 DEBUG: Current tab index: ${_tabController.index}, Type: $currentType');
    print('🔍 DEBUG: Selected account ID: $_selectedAccountId');

    // Validate account balance for expense and transfer transactions
    if (currentType == 'expense' || currentType == 'transfer') {
      final fromAccount = accountProvider.items.firstWhere(
        (account) => account.id == _selectedAccountId,
        orElse: () => throw Exception('Account not found'),
      );

      print('🔍 DEBUG: Account: ${fromAccount.name}, Balance: ${fromAccount.balance}, Amount: $amount');

      if (fromAccount.balance < amount) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '❌ Số dư trong ví "${fromAccount.name}" không đủ!\nSố dư hiện tại: ${fromAccount.balance.toStringAsFixed(0)} ${currency}\nCần: ${amount.toStringAsFixed(0)} ${currency}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    }

    // Validate transfer has both accounts
    if (currentType == 'transfer' && _selectedToAccountId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('❌ Vui lòng chọn ví nhận cho giao dịch chuyển khoản!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validate transfer accounts are different
    if (currentType == 'transfer' &&
        _selectedAccountId == _selectedToAccountId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ví gửi và ví nhận không thể giống nhau!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Create transaction
      final transaction = Transaction(
        id: const Uuid().v4(),
        type: currentType,
        accountId: _selectedAccountId!,
        toAccountId: _selectedToAccountId,
        categoryId: _selectedCategoryId,
        amount: amount,
        currency: currency,
        description: description,
        tags: _tags,
        dateTime: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          DateTime.now().hour,
          DateTime.now().minute,
          DateTime.now().second,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deleted: false,
      );

      // Add transaction to database
      await transactionProvider.addTransaction(transaction);

      // Update account balances based on transaction type
      await _updateAccountBalances(accountProvider, transaction);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã thêm giao dịch thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi thêm giao dịch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateAccountBalances(
      AccountProvider accountProvider, Transaction transaction) async {
    switch (transaction.type) {
      case 'expense':
        // Subtract amount from account balance
        final fromAccount = accountProvider.items.firstWhere(
          (account) => account.id == transaction.accountId,
        );
        await accountProvider.updateBalance(
          transaction.accountId,
          fromAccount.balance - transaction.amount,
        );
        break;

      case 'income':
      case 'refund':
        // Add amount to account balance
        final toAccount = accountProvider.items.firstWhere(
          (account) => account.id == transaction.accountId,
        );
        await accountProvider.updateBalance(
          transaction.accountId,
          toAccount.balance + transaction.amount,
        );
        break;

      case 'transfer':
        // Subtract from source account
        final fromAccount = accountProvider.items.firstWhere(
          (account) => account.id == transaction.accountId,
        );
        await accountProvider.updateBalance(
          transaction.accountId,
          fromAccount.balance - transaction.amount,
        );

        // Add to destination account
        final toAccount = accountProvider.items.firstWhere(
          (account) => account.id == transaction.toAccountId!,
        );
        await accountProvider.updateBalance(
          transaction.toAccountId!,
          toAccount.balance + transaction.amount,
        );
        break;
    }
  }
}
