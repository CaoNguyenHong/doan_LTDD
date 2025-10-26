import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../data/firestore_data_source.dart';

class TransactionProvider extends ChangeNotifier {
  final FirestoreDataSource _ds;
  final String _uid;

  TransactionProvider(this._ds, this._uid) {
    _watch();
  }

  List<Transaction> _items = [];
  bool _loading = true;
  String? _error;

  List<Transaction> get items => _items;
  bool get isLoading => _loading;
  String? get error => _error;

  void _watch() {
    _loading = true;
    notifyListeners();
    _ds.watchTx(_uid).listen((rows) {
      _items = rows
          .map((data) {
            try {
              return Transaction.fromMap(data['id'] as String, data);
            } catch (e) {
              debugPrint('⚠️ Transaction map error for ${data['id']}: $e');
              return null;
            }
          })
          .where((e) => e != null)
          .cast<Transaction>()
          .toList();
      _loading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> add({
    required String categoryId,
    required double amount,
    required String description,
    required DateTime dateTime,
    required String accountId,
    String type = 'expense', // TODO(CURSOR): Set according to form
    String? tags,
  }) async {
    await _ds.addTx(_uid, {
      'type': type,
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'accountId': accountId,
      'dateTime': dateTime.toUtc(),
      'tags': tags
              ?.split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
    });
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _ds.addTx(_uid, transaction.toMap());
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _ds.updateTx(_uid, transaction.id, transaction.toMap());
  }

  Future<void> remove(String id) => _ds.softDeleteTx(_uid, id);

  Future<void> deleteTransaction(String id) => _ds.softDeleteTx(_uid, id);

  // Legacy methods for backward compatibility
  List<Transaction> get transactions => _items;

  // Additional methods for filtering and calculations
  List<Transaction> getTransactionsByType(String type) {
    return _items.where((t) => t.type == type).toList();
  }

  List<Transaction> getTransactionsByAccount(String accountId) {
    return _items.where((t) => t.accountId == accountId).toList();
  }

  List<Transaction> getTransactionsByCategory(String categoryId) {
    return _items.where((t) => t.categoryId == categoryId).toList();
  }

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _items
        .where((t) => t.dateTime.isAfter(start) && t.dateTime.isBefore(end))
        .toList();
  }

  double getTotalByType(String type) {
    return _items
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalByAccount(String accountId) {
    return _items
        .where((t) => t.accountId == accountId)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalByCategory(String categoryId) {
    return _items
        .where((t) => t.categoryId == categoryId)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getTotalsByType() {
    final Map<String, double> totals = {};
    for (final transaction in _items) {
      totals[transaction.type] =
          (totals[transaction.type] ?? 0) + transaction.amount;
    }
    return totals;
  }

  Map<String, double> getTotalsByAccount() {
    final Map<String, double> totals = {};
    for (final transaction in _items) {
      totals[transaction.accountId] =
          (totals[transaction.accountId] ?? 0) + transaction.amount;
    }
    return totals;
  }

  Map<String, double> getTotalsByCategory() {
    final Map<String, double> totals = {};
    for (final transaction in _items) {
      totals[transaction.categoryId ?? 'unknown'] =
          (totals[transaction.categoryId ?? 'unknown'] ?? 0) +
              transaction.amount;
    }
    return totals;
  }

  List<Transaction> searchTransactions(String query) {
    if (query.isEmpty) return _items;
    return _items
        .where((t) =>
            t.description.toLowerCase().contains(query.toLowerCase()) ||
            t.tags
                .any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }
}
