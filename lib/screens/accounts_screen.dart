import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';
import '../utils/currency_formatter.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý ví'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () => _showAddAccountDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<AccountProvider>(
        builder: (context, accountProvider, _) {
          if (accountProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (accountProvider.error.isNotEmpty) {
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
                    'Lỗi: ${accountProvider.error}',
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

          if (accountProvider.accounts.isEmpty) {
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
                    'Chưa có ví nào',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy thêm ví đầu tiên của bạn',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddAccountDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm ví'),
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
                _buildSummaryCard(context, accountProvider),
                const SizedBox(height: 24),

                // Accounts list
                Text(
                  'Danh sách ví',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                ...accountProvider.accounts.map((account) =>
                    _buildAccountCard(context, account, accountProvider)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccountDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ví'),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, AccountProvider accountProvider) {
    final totalBalance = accountProvider.getTotalBalance();

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
                'Tổng số dư',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(totalBalance, currency: '\$'),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${accountProvider.accounts.length} ví',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
      BuildContext context, Account account, AccountProvider accountProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getAccountColor(account.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            account.typeIcon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Row(
          children: [
            Text(
              account.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (account.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Mặc định',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(account.typeDisplayName),
            const SizedBox(height: 4),
            Text(
              '${CurrencyFormatter.format(account.balance, currency: '\$')} ${account.currency}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: account.balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'set_default',
              child: Row(
                children: [
                  const Icon(Icons.star),
                  const SizedBox(width: 8),
                  Text(account.isDefault ? 'Bỏ mặc định' : 'Đặt mặc định'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'adjust_balance',
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  const Text('Điều chỉnh số dư'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  const Text('Chỉnh sửa'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) =>
              _handleAccountAction(value, account, accountProvider),
        ),
      ),
    );
  }

  Color _getAccountColor(String type) {
    switch (type) {
      case 'cash':
        return Colors.green;
      case 'bank':
        return Colors.blue;
      case 'card':
        return Colors.purple;
      case 'ewallet':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _handleAccountAction(
      String action, Account account, AccountProvider accountProvider) {
    switch (action) {
      case 'set_default':
        accountProvider.setDefaultAccount(account.id);
        break;
      case 'adjust_balance':
        _showAdjustBalanceDialog(context, account, accountProvider);
        break;
      case 'edit':
        _showEditAccountDialog(context, account, accountProvider);
        break;
      case 'delete':
        _showDeleteAccountDialog(context, account, accountProvider);
        break;
    }
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'cash';
    String selectedCurrency = 'USD';
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm ví mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên ví',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại ví',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('💵 Tiền mặt')),
                    DropdownMenuItem(
                        value: 'bank', child: Text('🏦 Ngân hàng')),
                    DropdownMenuItem(value: 'card', child: Text('💳 Thẻ')),
                    DropdownMenuItem(
                        value: 'ewallet', child: Text('📱 Ví điện tử')),
                  ],
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Tiền tệ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('USD - \$')),
                    DropdownMenuItem(value: 'VND', child: Text('VND - ₫')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR - €')),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedCurrency = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Số dư ban đầu',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Đặt làm ví mặc định'),
                  value: isDefault,
                  onChanged: (value) => setState(() => isDefault = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final account = Account(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    type: selectedType,
                    currency: selectedCurrency,
                    balance: double.tryParse(balanceController.text) ?? 0.0,
                    isDefault: isDefault,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  final accountProvider =
                      Provider.of<AccountProvider>(context, listen: false);
                  await accountProvider.addAccount(account);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đã thêm ví thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAccountDialog(
      BuildContext context, Account account, AccountProvider accountProvider) {
    final nameController = TextEditingController(text: account.name);
    String selectedType = account.type;
    String selectedCurrency = account.currency;
    bool isDefault = account.isDefault;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa ví'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên ví',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại ví',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('💵 Tiền mặt')),
                    DropdownMenuItem(
                        value: 'bank', child: Text('🏦 Ngân hàng')),
                    DropdownMenuItem(value: 'card', child: Text('💳 Thẻ')),
                    DropdownMenuItem(
                        value: 'ewallet', child: Text('📱 Ví điện tử')),
                  ],
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Tiền tệ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('USD - \$')),
                    DropdownMenuItem(value: 'VND', child: Text('VND - ₫')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR - €')),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedCurrency = value!),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Đặt làm ví mặc định'),
                  value: isDefault,
                  onChanged: (value) => setState(() => isDefault = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final updatedAccount = account.copyWith(
                    name: nameController.text,
                    type: selectedType,
                    currency: selectedCurrency,
                    isDefault: isDefault,
                    updatedAt: DateTime.now(),
                  );

                  await accountProvider.updateAccount(
                      account.id, updatedAccount);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đã cập nhật ví thành công!'),
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

  void _showAdjustBalanceDialog(
      BuildContext context, Account account, AccountProvider accountProvider) {
    final balanceController = TextEditingController(
        text: CurrencyFormatter.format(account.balance, currency: '\$')
            .replaceAll('\$', ''));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Điều chỉnh số dư'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ví: ${account.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Số dư mới',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBalance = double.tryParse(balanceController.text);
              if (newBalance != null) {
                await accountProvider.updateAccountBalance(
                    account.id, newBalance);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã cập nhật số dư thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(
      BuildContext context, Account account, AccountProvider accountProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ví'),
        content: Text('Bạn có chắc chắn muốn xóa ví "${account.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await accountProvider.deleteAccount(account.id);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã xóa ví thành công!'),
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
}
