import 'package:flutter/foundation.dart';
import '../hive/expense.dart';
import '../data/firestore_data_source.dart';
import '../service/currency_service.dart';
import '../service/api_service.dart';
import 'package:uuid/uuid.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirestoreDataSource _ds;
  final String _uid;

  ExpenseProvider(this._ds, this._uid) {
    _watch();
  }

  List<Expense> _items = [];
  bool _loading = true;
  String? _error;
  String _filterMode = 'daily';
  DateTime _selectedDate = DateTime.now();
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  List<Expense> get items => _items;
  bool get isLoading => _loading;
  String? get error => _error;
  String get filterMode => _filterMode;
  DateTime get selectedDate => _selectedDate;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;

  void _watch() {
    _loading = true;
    notifyListeners();
    _ds.watchExpenses(_uid).listen((rows) {
      _items = rows.map((data) => Expense.fromMap(data)).toList();
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
    required String category,
    required double amount,
    required String description,
    DateTime? dateTime,
    String? currency,
  }) async {
    final expense = Expense(
      id: const Uuid().v4(),
      category: category,
      amount: amount,
      description: description,
      dateTime: dateTime ?? DateTime.now(),
      currency: currency ?? 'VND', // TODO(CURSOR): Set default currency
    );

    await _ds.addExpense(_uid, expense.toMap());
  }

  Future<void> addExpense(Expense expense) async {
    await _ds.addExpense(_uid, expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    await _ds.updateExpense(_uid, expense.id, expense.toMap());
  }

  Future<void> deleteExpense(String id) => _ds.softDeleteExpense(_uid, id);

  // Legacy methods for backward compatibility
  List<Expense> get expenses => _items;

  // Filter methods
  void setFilterMode(String mode) {
    _filterMode = mode;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setCustomDateRange(DateTime? start, DateTime? end) {
    _customStartDate = start;
    _customEndDate = end;
    notifyListeners();
  }

  List<Expense> getFilteredExpenses() {
    switch (_filterMode) {
      case 'daily':
        return _getDailyExpenses();
      case 'weekly':
        return _getWeeklyExpenses();
      case 'monthly':
        return _getMonthlyExpenses();
      case 'custom':
        return _getCustomRangeExpenses();
      default:
        return _items;
    }
  }

  List<Expense> _getDailyExpenses() {
    final startOfDay =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _items
        .where((expense) =>
            expense.dateTime.isAfter(startOfDay) &&
            expense.dateTime.isBefore(endOfDay))
        .toList();
  }

  List<Expense> _getWeeklyExpenses() {
    final startOfWeek =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return _items
        .where((expense) =>
            expense.dateTime.isAfter(startOfWeek) &&
            expense.dateTime.isBefore(endOfWeek))
        .toList();
  }

  List<Expense> _getMonthlyExpenses() {
    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);

    return _items
        .where((expense) =>
            expense.dateTime.isAfter(startOfMonth) &&
            expense.dateTime.isBefore(endOfMonth))
        .toList();
  }

  List<Expense> _getCustomRangeExpenses() {
    if (_customStartDate == null || _customEndDate == null) {
      return _items;
    }

    return _items
        .where((expense) =>
            expense.dateTime.isAfter(_customStartDate!) &&
            expense.dateTime.isBefore(_customEndDate!))
        .toList();
  }

  // Calculation methods
  double getTotalAmount() {
    return getFilteredExpenses()
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getTotalAmountByCategory(String category) {
    return getFilteredExpenses()
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> getTotalsByCategory() {
    final Map<String, double> totals = {};
    for (final expense in getFilteredExpenses()) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  Map<String, double> getTotalsByCurrency() {
    final Map<String, double> totals = {};
    for (final expense in getFilteredExpenses()) {
      totals['VND'] = (totals['VND'] ?? 0) + expense.amount; // Default currency
    }
    return totals;
  }

  double getAverageAmount() {
    final filtered = getFilteredExpenses();
    if (filtered.isEmpty) return 0.0;
    return getTotalAmount() / filtered.length;
  }

  double getHighestAmount() {
    final filtered = getFilteredExpenses();
    if (filtered.isEmpty) return 0.0;
    return filtered.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
  }

  double getLowestAmount() {
    final filtered = getFilteredExpenses();
    if (filtered.isEmpty) return 0.0;
    return filtered.map((e) => e.amount).reduce((a, b) => a < b ? a : b);
  }

  // AI Integration methods
  Future<Expense?> parseExpenseFromText(String text) async {
    try {
      final apiService = AIService(apiKey: 'demo-key');
      final result = await apiService.processExpenseInput(text);

      if (result.isNotEmpty) {
        final expense = Expense(
          id: const Uuid().v4(),
          category: result['category'] ?? 'Other',
          amount: (result['amount'] ?? 0.0).toDouble(),
          description: result['description'] ?? text,
          dateTime: DateTime.now(),
        );

        await addExpense(expense);
        return expense;
      }
    } catch (e) {
      print('Error parsing expense from text: $e');
    }
    return null;
  }

  // Currency conversion methods
  Future<double> convertCurrency(
      double amount, String fromCurrency, String toCurrency) async {
    try {
      return await CurrencyService.convertAmount(
          amount, fromCurrency, toCurrency);
    } catch (e) {
      print('Error converting currency: $e');
      return amount; // Return original amount if conversion fails
    }
  }

  // Search methods
  List<Expense> searchExpenses(String query) {
    if (query.isEmpty) return getFilteredExpenses();
    return getFilteredExpenses()
        .where((expense) =>
            expense.description.toLowerCase().contains(query.toLowerCase()) ||
            expense.category.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Statistics methods
  Map<String, int> getCountByCategory() {
    final Map<String, int> counts = {};
    for (final expense in getFilteredExpenses()) {
      counts[expense.category] = (counts[expense.category] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> getCountByCurrency() {
    final Map<String, int> counts = {};
    for (final _ in getFilteredExpenses()) {
      counts['VND'] = (counts['VND'] ?? 0) + 1; // Default currency
    }
    return counts;
  }

  // Date range methods
  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _items
        .where((expense) =>
            expense.dateTime.isAfter(start) && expense.dateTime.isBefore(end))
        .toList();
  }

  List<Expense> getExpensesByMonth(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);
    return getExpensesByDateRange(startOfMonth, endOfMonth);
  }

  List<Expense> getExpensesByYear(int year) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);
    return getExpensesByDateRange(startOfYear, endOfYear);
  }

  // Additional methods for backward compatibility
  Future<void> convertExpensesToCurrency(
      String fromCurrency, String toCurrency) async {
    for (final expense in _items) {
      if (fromCurrency == 'VND') {
        // Default currency check
        final convertedAmount =
            await convertCurrency(expense.amount, fromCurrency, toCurrency);
        final updatedExpense = Expense(
          id: expense.id,
          category: expense.category,
          amount: convertedAmount,
          description: expense.description,
          dateTime: expense.dateTime,
        );
        await updateExpense(updatedExpense);
      }
    }
  }
}
