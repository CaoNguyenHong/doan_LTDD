import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../data/firestore_budget_repo.dart';

class BudgetProvider with ChangeNotifier {
  final String uid;
  final FirestoreBudgetRepo _budgetRepo;

  List<Budget> _budgets = [];
  bool _isLoading = false;
  String _error = '';

  BudgetProvider({required this.uid})
      : _budgetRepo = FirestoreBudgetRepo(uid: uid) {
    _watchBudgets();
  }

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String get error => _error;

  void _watchBudgets() {
    _setLoading(true);
    _budgetRepo.watchBudgets().listen(
      (budgets) {
        _budgets = budgets;
        _error = '';
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        _error = 'Không thể tải danh sách ngân sách: $error';
        _setLoading(false);
        notifyListeners();
      },
    );
  }

  Future<void> addBudget(Budget budget) async {
    _setLoading(true);
    try {
      await _budgetRepo.addBudget(budget);
      _error = '';
    } catch (e) {
      _error = 'Không thể thêm ngân sách: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> updateBudget(String budgetId, Budget budget) async {
    _setLoading(true);
    try {
      await _budgetRepo.updateBudget(budgetId, budget);
      _error = '';
    } catch (e) {
      _error = 'Không thể cập nhật ngân sách: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> deleteBudget(String budgetId) async {
    _setLoading(true);
    try {
      await _budgetRepo.deleteBudget(budgetId);
      _error = '';
    } catch (e) {
      _error = 'Không thể xóa ngân sách: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> updateBudgetSpent(String budgetId, double spent) async {
    _setLoading(true);
    try {
      await _budgetRepo.updateBudgetSpent(budgetId, spent);
      _error = '';
    } catch (e) {
      _error = 'Không thể cập nhật số tiền đã chi: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  List<Budget> getBudgetsByPeriod(String period) {
    return _budgets.where((budget) => budget.period == period).toList();
  }

  List<Budget> getBudgetsByCategory(String categoryId) {
    return _budgets.where((budget) => budget.categoryId == categoryId).toList();
  }

  List<Budget> getBudgetsByMonth(String month) {
    return _budgets.where((budget) => budget.month == month).toList();
  }

  List<Budget> getOverBudgetBudgets() {
    return _budgets.where((budget) => budget.isOverBudget).toList();
  }

  List<Budget> getNearLimitBudgets() {
    return _budgets.where((budget) => budget.isNearLimit).toList();
  }

  List<Budget> getWarningBudgets() {
    return _budgets.where((budget) => budget.isWarning).toList();
  }

  double getTotalBudgetLimit() {
    return _budgets.fold(0.0, (sum, budget) => sum + budget.limit);
  }

  double getTotalBudgetSpent() {
    return _budgets.fold(0.0, (sum, budget) => sum + budget.spent);
  }

  double getTotalBudgetRemaining() {
    return getTotalBudgetLimit() - getTotalBudgetSpent();
  }

  double getBudgetUtilizationPercentage() {
    final totalLimit = getTotalBudgetLimit();
    if (totalLimit == 0) return 0;
    return (getTotalBudgetSpent() / totalLimit) * 100;
  }

  Map<String, double> getBudgetBreakdown() {
    final Map<String, double> breakdown = {};
    for (var budget in _budgets) {
      final key = budget.categoryId ?? 'global';
      breakdown[key] = (breakdown[key] ?? 0) + budget.spent;
    }
    return breakdown;
  }

  bool hasOverBudget() {
    return _budgets.any((budget) => budget.isOverBudget);
  }

  bool hasNearLimit() {
    return _budgets.any((budget) => budget.isNearLimit);
  }

  bool hasWarning() {
    return _budgets.any((budget) => budget.isWarning);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
