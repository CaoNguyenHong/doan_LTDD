import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';
import '../providers/settings_provider.dart';
import '../service/currency_service.dart';
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
        title: const Text(
          'Quản lý ví',
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
            onPressed: () => _showAddAccountDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: Consumer<AccountProvider>(
        builder: (context, accountProvider, _) {
          if (accountProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (accountProvider.error?.isNotEmpty == true) {
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
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final currencySymbol =
        CurrencyService.getCurrencySymbol(settingsProvider.currency);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tổng số dư',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(totalBalance, currency: currencySymbol),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.wallet,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${accountProvider.accounts.length} ví',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
      BuildContext context, Account account, AccountProvider accountProvider) {
    final currencySymbol = CurrencyService.getCurrencySymbol(account.currency);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAccountDetails(context, account),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getAccountColor(account.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  account.typeIcon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            account.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (account.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Mặc định',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.typeDisplayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${CurrencyFormatter.format(account.balance, currency: currencySymbol)} ${account.currency}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: account.balance >= 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.red,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'set_default',
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color:
                              account.isDefault ? Colors.orange : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                            account.isDefault ? 'Bỏ mặc định' : 'Đặt mặc định'),
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
                        Icon(Icons.delete, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Text('Xóa',
                            style: TextStyle(color: Colors.red.shade600)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) =>
                    _handleAccountAction(value, account, accountProvider),
              ),
            ],
          ),
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
      case 'edit':
        _showEditAccountDialog(context, account, accountProvider);
        break;
      case 'delete':
        _showDeleteAccountDialog(context, account, accountProvider);
        break;
    }
  }

  void _showAccountDetails(BuildContext context, Account account) {
    final currencySymbol = CurrencyService.getCurrencySymbol(account.currency);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(account.typeIcon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(account.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Loại ví', account.typeDisplayName),
            _buildDetailRow('Tiền tệ', '${account.currency} ($currencySymbol)'),
            _buildDetailRow('Số dư',
                '${CurrencyFormatter.format(account.balance, currency: currencySymbol)}'),
            _buildDetailRow(
                'Trạng thái', account.isDefault ? 'Ví mặc định' : 'Ví thường'),
            _buildDetailRow('Ngày tạo',
                '${account.createdAt.day}/${account.createdAt.month}/${account.createdAt.year}'),
            _buildDetailRow('Cập nhật cuối',
                '${account.updatedAt.day}/${account.updatedAt.month}/${account.updatedAt.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'cash';
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final accountProvider =
        Provider.of<AccountProvider>(context, listen: false);
    String selectedCurrency =
        settingsProvider.currency; // Use app's default currency
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
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
                  items:
                      settingsProvider.getSupportedCurrencies().map((currency) {
                    final symbol = CurrencyService.getCurrencySymbol(currency);
                    return DropdownMenuItem(
                      value: currency,
                      child: Text('$currency - $symbol'),
                    );
                  }).toList(),
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

                  await accountProvider.addAccount(account);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
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
    final balanceController = TextEditingController(
      text: CurrencyFormatter.format(account.balance,
              currency: CurrencyService.getCurrencySymbol(account.currency))
          .replaceAll(CurrencyService.getCurrencySymbol(account.currency), ''),
    );
    String selectedType = account.type;
    String selectedCurrency = account.currency;
    bool isDefault = account.isDefault;
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
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
                  items:
                      settingsProvider.getSupportedCurrencies().map((currency) {
                    final symbol = CurrencyService.getCurrencySymbol(currency);
                    return DropdownMenuItem(
                      value: currency,
                      child: Text('$currency - $symbol'),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => selectedCurrency = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText:
                        'Số dư (${CurrencyService.getCurrencySymbol(selectedCurrency)})',
                    border: const OutlineInputBorder(),
                    prefixText:
                        '${CurrencyService.getCurrencySymbol(selectedCurrency)} ',
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
              onPressed: () => Navigator.pop(dialogContext),
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

                  await accountProvider.updateAccount(updatedAccount);

                  // Update balance if changed
                  final newBalance = double.tryParse(balanceController.text);
                  if (newBalance != null && newBalance != account.balance) {
                    await accountProvider.updateBalance(account.id, newBalance);
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
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
