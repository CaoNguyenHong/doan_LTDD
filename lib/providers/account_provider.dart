import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../data/firestore_data_source.dart';
import '../utils/sample_data.dart';

class AccountProvider extends ChangeNotifier {
  final FirestoreDataSource _ds;
  final String _uid;

  AccountProvider(this._ds, this._uid) {
    _watch();
  }

  List<Account> _items = [];
  bool _loading = true;
  String? _error;

  List<Account> get items => _items;
  bool get isLoading => _loading;
  String? get error => _error;

  void _watch() {
    _loading = true;
    notifyListeners();
    _ds.watchAccounts(_uid).listen((rows) {
      _items = rows.map((data) => Account.fromMap(data['id'], data)).toList();

      // Create sample data if no accounts exist
      if (_items.isEmpty) {
        _createSampleData();
      }

      _loading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> _createSampleData() async {
    try {
      final sampleAccounts = SampleData.getDefaultAccounts();
      for (final account in sampleAccounts) {
        await _ds.addAccount(_uid, account.toMap());
      }
    } catch (e) {
      print('Error creating sample accounts: $e');
    }
  }

  Future<void> add({
    required String name,
    required String type,
    required String currency,
    double balance = 0.0,
    bool isDefault = false,
  }) async {
    await _ds.addAccount(_uid, {
      'name': name,
      'type': type,
      'currency': currency,
      'balance': balance,
      'isDefault': isDefault,
    });
  }

  Future<void> addAccount(Account account) async {
    await _ds.addAccount(_uid, account.toMap());
  }

  Future<void> updateAccount(Account account) async {
    await _ds.updateAccount(_uid, account.id, account.toMap());
  }

  Future<void> deleteAccount(String id) => _ds.softDeleteAccount(_uid, id);

  Future<void> updateBalance(String id, double newBalance) async {
    await _ds.updateAccount(_uid, id, {'balance': newBalance});
  }

  Future<void> setDefaultAccount(String id) async {
    // First, unset all other accounts as default
    for (final account in _items) {
      if (account.isDefault && account.id != id) {
        await _ds.updateAccount(_uid, account.id, {'isDefault': false});
      }
    }
    // Then set the selected account as default
    await _ds.updateAccount(_uid, id, {'isDefault': true});
  }

  // Legacy methods for backward compatibility
  List<Account> get accounts => _items;

  // Additional methods
  Account? getDefaultAccount() {
    try {
      return _items.firstWhere((account) => account.isDefault);
    } catch (e) {
      return _items.isNotEmpty ? _items.first : null;
    }
  }

  List<Account> getAccountsByType(String type) {
    return _items.where((account) => account.type == type).toList();
  }

  double getTotalBalance() {
    return _items.fold(0.0, (sum, account) => sum + account.balance);
  }

  double getTotalBalanceByType(String type) {
    return _items
        .where((account) => account.type == type)
        .fold(0.0, (sum, account) => sum + account.balance);
  }

  Map<String, double> getTotalsByType() {
    final Map<String, double> totals = {};
    for (final account in _items) {
      totals[account.type] = (totals[account.type] ?? 0) + account.balance;
    }
    return totals;
  }

  Map<String, double> getTotalsByCurrency() {
    final Map<String, double> totals = {};
    for (final account in _items) {
      totals[account.currency] =
          (totals[account.currency] ?? 0) + account.balance;
    }
    return totals;
  }

  // Additional methods for backward compatibility
  Future<void> updateAccountBalance(String id, double newBalance) async {
    await updateBalance(id, newBalance);
  }
}
