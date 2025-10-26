import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../data/firestore_data_source.dart';

class BudgetProvider extends ChangeNotifier {
  final FirestoreDataSource _ds;
  final String _uid;

  BudgetProvider(this._ds, this._uid) {
    _watch();
  }

  List<Budget> _items = [];
  bool _loading = true;
  String? _error;

  List<Budget> get items => _items;
  bool get isLoading => _loading;
  String? get error => _error;

  void _watch() {
    _loading = true;
    notifyListeners();
    _ds.watchBudgets(_uid).listen((rows) {
      _items = rows.map((data) => Budget.fromMap(data['id'], data)).toList();
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
    required String period,
    required String categoryId,
    required double limit,
    String? month,
  }) async {
    await _ds.addBudget(_uid, {
      'period': period,
      'categoryId': categoryId,
      'limit': limit,
      'spent': 0.0,
      'month': month,
    });
  }

  Future<void> addBudget(Budget budget) async {
    await _ds.addBudget(_uid, budget.toMap());
  }

  Future<void> updateBudget(Budget budget) async {
    await _ds.updateBudget(_uid, budget.id, budget.toMap());
  }

  Future<void> deleteBudget(String id) => _ds.softDeleteBudget(_uid, id);

  Future<void> updateSpent(String id, double spent) async {
    await _ds.updateBudget(_uid, id, {'spent': spent});
  }

  // Legacy methods for backward compatibility
  List<Budget> get budgets => _items;

  // Additional methods
  List<Budget> getBudgetsByPeriod(String period) {
    return _items.where((budget) => budget.period == period).toList();
  }

  List<Budget> getBudgetsByCategory(String categoryId) {
    return _items.where((budget) => budget.categoryId == categoryId).toList();
  }

  List<Budget> getBudgetsByMonth(String month) {
    return _items.where((budget) => budget.month == month).toList();
  }

  List<Budget> getOverBudgetBudgets() {
    return _items.where((budget) => budget.isOverBudget).toList();
  }

  List<Budget> getNearLimitBudgets() {
    return _items.where((budget) => budget.isNearLimit).toList();
  }

  double getTotalLimit() {
    return _items.fold(0.0, (sum, budget) => sum + budget.limit);
  }

  double getTotalSpent() {
    return _items.fold(0.0, (sum, budget) => sum + budget.spent);
  }

  double getTotalRemaining() {
    return _items.fold(0.0, (sum, budget) => sum + budget.remaining);
  }

  double getTotalLimitByPeriod(String period) {
    return _items
        .where((budget) => budget.period == period)
        .fold(0.0, (sum, budget) => sum + budget.limit);
  }

  double getTotalSpentByPeriod(String period) {
    return _items
        .where((budget) => budget.period == period)
        .fold(0.0, (sum, budget) => sum + budget.spent);
  }

  double getTotalLimitByCategory(String categoryId) {
    return _items
        .where((budget) => budget.categoryId == categoryId)
        .fold(0.0, (sum, budget) => sum + budget.limit);
  }

  double getTotalSpentByCategory(String categoryId) {
    return _items
        .where((budget) => budget.categoryId == categoryId)
        .fold(0.0, (sum, budget) => sum + budget.spent);
  }

  Map<String, double> getTotalsByPeriod() {
    final Map<String, double> totals = {};
    for (final budget in _items) {
      totals[budget.period] = (totals[budget.period] ?? 0) + budget.limit;
    }
    return totals;
  }

  Map<String, double> getSpentByPeriod() {
    final Map<String, double> totals = {};
    for (final budget in _items) {
      totals[budget.period] = (totals[budget.period] ?? 0) + budget.spent;
    }
    return totals;
  }

  Map<String, double> getTotalsByCategory() {
    final Map<String, double> totals = {};
    for (final budget in _items) {
      totals[budget.categoryId ?? 'unknown'] =
          (totals[budget.categoryId ?? 'unknown'] ?? 0) + budget.limit;
    }
    return totals;
  }

  Map<String, double> getSpentByCategory() {
    final Map<String, double> totals = {};
    for (final budget in _items) {
      totals[budget.categoryId ?? 'unknown'] =
          (totals[budget.categoryId ?? 'unknown'] ?? 0) + budget.spent;
    }
    return totals;
  }

  double getUtilizationPercentage() {
    final totalLimit = getTotalLimit();
    if (totalLimit == 0) return 0.0;
    return (getTotalSpent() / totalLimit) * 100;
  }

  double getUtilizationPercentageByPeriod(String period) {
    final totalLimit = getTotalLimitByPeriod(period);
    if (totalLimit == 0) return 0.0;
    return (getTotalSpentByPeriod(period) / totalLimit) * 100;
  }

  double getUtilizationPercentageByCategory(String categoryId) {
    final totalLimit = getTotalLimitByCategory(categoryId);
    if (totalLimit == 0) return 0.0;
    return (getTotalSpentByCategory(categoryId) / totalLimit) * 100;
  }

  // Additional methods for backward compatibility
  bool hasOverBudget() {
    return _items.any((budget) => budget.isOverBudget);
  }

  bool hasNearLimit() {
    return _items.any((budget) => budget.isNearLimit);
  }

  double getTotalBudgetLimit() {
    return _items.fold(0.0, (sum, budget) => sum + budget.limit);
  }

  double getTotalBudgetSpent() {
    return _items.fold(0.0, (sum, budget) => sum + budget.spent);
  }

  double getBudgetUtilizationPercentage() {
    final totalLimit = getTotalBudgetLimit();
    final totalSpent = getTotalBudgetSpent();
    if (totalLimit == 0) return 0.0;
    return (totalSpent / totalLimit) * 100;
  }
}
