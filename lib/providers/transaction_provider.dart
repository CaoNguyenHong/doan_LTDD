import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../data/firestore_transaction_repo.dart';

class TransactionProvider with ChangeNotifier {
  final String uid;
  final FirestoreTransactionRepo _transactionRepo;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String _error = '';

  TransactionProvider({required this.uid})
      : _transactionRepo = FirestoreTransactionRepo(uid: uid) {
    _watchTransactions();
  }

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get error => _error;

  void _watchTransactions() {
    _setLoading(true);
    _transactionRepo.watchTransactions().listen(
      (transactions) {
        _transactions = transactions.cast<Transaction>();
        _error = '';
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        _error = 'Không thể tải danh sách giao dịch: $error';
        _setLoading(false);
        notifyListeners();
      },
    );
  }

  Future<void> addTransaction(Transaction transaction) async {
    _setLoading(true);
    try {
      await _transactionRepo.addTransaction(transaction);
      _error = '';
    } catch (e) {
      _error = 'Không thể thêm giao dịch: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> updateTransaction(
      String transactionId, Transaction transaction) async {
    _setLoading(true);
    try {
      await _transactionRepo.updateTransaction(transactionId, transaction);
      _error = '';
    } catch (e) {
      _error = 'Không thể cập nhật giao dịch: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> deleteTransaction(String transactionId) async {
    _setLoading(true);
    try {
      await _transactionRepo.deleteTransaction(transactionId);
      _error = '';
    } catch (e) {
      _error = 'Không thể xóa giao dịch: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<List<Transaction>> searchTransactions(String query) async {
    try {
      return await _transactionRepo
          .searchTransactions(query)
          .then((list) => list.cast<Transaction>());
    } catch (e) {
      _error = 'Không thể tìm kiếm giao dịch: $e';
      return [];
    }
  }

  Future<List<Transaction>> getTransactionsByFilter({
    String? accountId,
    String? categoryId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<String>? tags,
    String? searchQuery,
  }) async {
    try {
      return await _transactionRepo
          .getTransactionsByFilter(
            accountId: accountId,
            categoryId: categoryId,
            type: type,
            startDate: startDate,
            endDate: endDate,
            minAmount: minAmount,
            maxAmount: maxAmount,
            tags: tags,
            searchQuery: searchQuery,
          )
          .then((list) => list.cast<Transaction>());
    } catch (e) {
      _error = 'Không thể lọc giao dịch: $e';
      return [];
    }
  }

  List<Transaction> getTransactionsByType(String type) {
    return _transactions.where((tx) => tx.type == type).toList();
  }

  List<Transaction> getTransactionsByAccount(String accountId) {
    return _transactions.where((tx) => tx.accountId == accountId).toList();
  }

  List<Transaction> getTransactionsByCategory(String categoryId) {
    return _transactions.where((tx) => tx.categoryId == categoryId).toList();
  }

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions
        .where((tx) => tx.dateTime.isAfter(start) && tx.dateTime.isBefore(end))
        .toList();
  }

  double getTotalByType(String type) {
    return _transactions
        .where((tx) => tx.type == type)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getTotalByAccount(String accountId) {
    return _transactions
        .where((tx) => tx.accountId == accountId)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getTotalByCategory(String categoryId) {
    return _transactions
        .where((tx) => tx.categoryId == categoryId)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getTotalIncome() {
    return getTotalByType('income');
  }

  double getTotalExpense() {
    return getTotalByType('expense');
  }

  double getTotalRefund() {
    return getTotalByType('refund');
  }

  double getNetAmount() {
    return getTotalIncome() - getTotalExpense() + getTotalRefund();
  }

  Map<String, double> getCategoryBreakdown() {
    final Map<String, double> breakdown = {};
    for (var tx in _transactions) {
      if (tx.type == 'expense' && tx.categoryId != null) {
        breakdown[tx.categoryId!] =
            (breakdown[tx.categoryId!] ?? 0) + tx.amount;
      }
    }
    return breakdown;
  }

  Map<String, double> getAccountBreakdown() {
    final Map<String, double> breakdown = {};
    for (var tx in _transactions) {
      breakdown[tx.accountId] = (breakdown[tx.accountId] ?? 0) + tx.amount;
    }
    return breakdown;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
