import 'package:flutter/foundation.dart';
import '../models/recurring.dart';
import '../data/firestore_data_source.dart';

class RecurringProvider extends ChangeNotifier {
  final FirestoreDataSource _ds;
  final String _uid;

  RecurringProvider(this._ds, this._uid) {
    _watch();
  }

  List<Recurring> _items = [];
  bool _loading = true;
  String? _error;

  List<Recurring> get items => _items;
  bool get isLoading => _loading;
  String? get error => _error;

  void _watch() {
    _loading = true;
    notifyListeners();
    _ds.watchRecurring(_uid).listen((rows) {
      _items = rows.map((data) => Recurring.fromMap(data['id'], data)).toList();
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
    required String rule,
    required Map<String, dynamic> templateTx,
    DateTime? nextRun,
    bool active = true,
  }) async {
    await _ds.addRecurring(_uid, {
      'rule': rule,
      'templateTx': templateTx,
      'nextRun': nextRun?.toUtc(),
      'active': active,
    });
  }

  Future<void> addRecurring(Recurring recurring) async {
    await _ds.addRecurring(_uid, recurring.toMap());
  }

  Future<void> updateRecurring(Recurring recurring) async {
    await _ds.updateRecurring(_uid, recurring.id, recurring.toMap());
  }

  Future<void> deleteRecurring(String id) => _ds.softDeleteRecurring(_uid, id);

  Future<void> updateNextRun(String id, DateTime nextRun) async {
    await _ds.updateRecurring(_uid, id, {'nextRun': nextRun.toUtc()});
  }

  Future<void> toggleActive(String id, bool active) async {
    await _ds.updateRecurring(_uid, id, {'active': active});
  }

  // Legacy methods for backward compatibility
  List<Recurring> get recurrings => _items;

  // Additional methods
  List<Recurring> getActiveRecurrings() {
    return _items.where((recurring) => recurring.active).toList();
  }

  List<Recurring> getInactiveRecurrings() {
    return _items.where((recurring) => !recurring.active).toList();
  }

  List<Recurring> getDueTodayRecurrings() {
    return _items.where((recurring) => recurring.isDueToday).toList();
  }

  List<Recurring> getOverdueRecurrings() {
    return _items.where((recurring) => recurring.isOverdue).toList();
  }

  List<Recurring> getRecurringsByFrequency(String frequency) {
    return _items
        .where((recurring) => recurring.frequency == frequency)
        .toList();
  }

  List<Recurring> getRecurringsByType(String type) {
    return _items
        .where((recurring) => recurring.templateTx.type == type)
        .toList();
  }

  List<Recurring> getRecurringsByAccount(String accountId) {
    return _items
        .where((recurring) => recurring.templateTx.accountId == accountId)
        .toList();
  }

  List<Recurring> getRecurringsByCategory(String categoryId) {
    return _items
        .where((recurring) => recurring.templateTx.categoryId == categoryId)
        .toList();
  }

  Map<String, int> getCountByFrequency() {
    final Map<String, int> counts = {};
    for (final recurring in _items) {
      counts[recurring.frequency] = (counts[recurring.frequency] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> getCountByType() {
    final Map<String, int> counts = {};
    for (final recurring in _items) {
      counts[recurring.templateTx.type] =
          (counts[recurring.templateTx.type] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, double> getTotalsByType() {
    final Map<String, double> totals = {};
    for (final recurring in _items) {
      totals[recurring.templateTx.type] =
          (totals[recurring.templateTx.type] ?? 0) +
              recurring.templateTx.amount;
    }
    return totals;
  }

  Map<String, double> getTotalsByAccount() {
    final Map<String, double> totals = {};
    for (final recurring in _items) {
      totals[recurring.templateTx.accountId] =
          (totals[recurring.templateTx.accountId] ?? 0) +
              recurring.templateTx.amount;
    }
    return totals;
  }

  Map<String, double> getTotalsByCategory() {
    final Map<String, double> totals = {};
    for (final recurring in _items) {
      totals[recurring.templateTx.categoryId ?? 'unknown'] =
          (totals[recurring.templateTx.categoryId ?? 'unknown'] ?? 0) +
              recurring.templateTx.amount;
    }
    return totals;
  }

  double getTotalAmount() {
    return _items.fold(
        0.0, (sum, recurring) => sum + recurring.templateTx.amount);
  }

  double getTotalAmountByType(String type) {
    return _items
        .where((recurring) => recurring.templateTx.type == type)
        .fold(0.0, (sum, recurring) => sum + recurring.templateTx.amount);
  }

  double getTotalAmountByAccount(String accountId) {
    return _items
        .where((recurring) => recurring.templateTx.accountId == accountId)
        .fold(0.0, (sum, recurring) => sum + recurring.templateTx.amount);
  }

  double getTotalAmountByCategory(String categoryId) {
    return _items
        .where((recurring) => recurring.templateTx.categoryId == categoryId)
        .fold(0.0, (sum, recurring) => sum + recurring.templateTx.amount);
  }

  int getActiveCount() {
    return _items.where((recurring) => recurring.active).length;
  }

  int getInactiveCount() {
    return _items.where((recurring) => !recurring.active).length;
  }

  int getDueTodayCount() {
    return _items.where((recurring) => recurring.isDueToday).length;
  }

  int getOverdueCount() {
    return _items.where((recurring) => recurring.isOverdue).length;
  }
}
