import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

class SampleData {
  static List<Account> getDefaultAccounts() {
    return [
      Account(
        id: const Uuid().v4(),
        name: 'Ví tiền mặt',
        type: 'cash',
        currency: 'VND',
        balance: 500000.0,
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Account(
        id: const Uuid().v4(),
        name: 'Ngân hàng Vietcombank',
        type: 'bank',
        currency: 'VND',
        balance: 2000000.0,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Account(
        id: const Uuid().v4(),
        name: 'Thẻ tín dụng',
        type: 'card',
        currency: 'VND',
        balance: 0.0,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  static List<Transaction> getSampleTransactions() {
    return [
      Transaction(
        id: const Uuid().v4(),
        type: 'expense',
        accountId: 'cash-account-id',
        categoryId: 'food',
        amount: 50000.0,
        currency: 'VND',
        description: 'Ăn trưa tại quán cơm',
        tags: ['ăn uống', 'trưa'],
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        deleted: false,
      ),
      Transaction(
        id: const Uuid().v4(),
        type: 'expense',
        accountId: 'cash-account-id',
        categoryId: 'transport',
        amount: 30000.0,
        currency: 'VND',
        description: 'Đi xe máy',
        tags: ['giao thông'],
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        deleted: false,
      ),
    ];
  }

  static List<Budget> getSampleBudgets() {
    final currentMonth =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    return [
      Budget(
        id: const Uuid().v4(),
        period: 'monthly',
        month: currentMonth,
        categoryId: 'food',
        limit: 2000000.0,
        spent: 500000.0,
        updatedAt: DateTime.now(),
      ),
      Budget(
        id: const Uuid().v4(),
        period: 'monthly',
        month: currentMonth,
        categoryId: 'transport',
        limit: 500000.0,
        spent: 300000.0,
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
