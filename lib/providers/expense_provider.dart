import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:spend_sage/service/api_service.dart';
import 'package:spend_sage/service/adaptive_expense_parser.dart';
import 'package:spend_sage/data/firestore_data_source.dart';
import 'package:spend_sage/data/firestore_expense_repo.dart';
import 'package:uuid/uuid.dart';

class ExpenseProvider with ChangeNotifier {
  final AIService _aiService;
  late final ExpenseRepo _expenseRepo;
  List<Expense> _expenses = [];
  String _filterMode = 'daily';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String _error = '';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  /// Factory constructor for Firestore
  ExpenseProvider.firestore() : _aiService = AIService(apiKey: '') {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _expenseRepo = FirestoreExpenseRepo(
        uid: user.uid,
        dataSource: FirestoreDataSource(),
      );
      _watchExpenses();
    } else {
      // Fallback to Hive for development
      _expenseRepo = FirestoreExpenseRepo(
        uid: 'demo-user',
        dataSource: FirestoreDataSource(),
      );
      _watchExpenses();
    }
  }

  /// Legacy constructor for Hive (deprecated)
  ExpenseProvider({
    required dynamic
        databaseService, // TODO(CURSOR): Remove when fully migrated
    required AIService aiService,
  }) : _aiService = aiService {
    // TODO(CURSOR): This is deprecated, use ExpenseProvider.firestore() instead
    _loadExpenses();
  }

  List<Expense> get expenses => _filterExpenses();
  String get filterMode => _filterMode;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String get error => _error;
  double get totalAmount => _calculateTotal();

  Future<void> deleteExpense(String id) async {
    _setLoading(true);
    try {
      await _expenseRepo.remove(id);
      _error = '';
    } catch (e) {
      _error = 'Failed to delete expense: $e';
    }
    _setLoading(false);
  }

  Future<void> updateExpense(
    String id,
    String description,
    double amount,
    String category,
  ) async {
    _setLoading(true);
    try {
      final updatedExpense = Expense(
        id: id,
        category: category,
        amount: amount,
        description: description,
        dateTime: DateTime.now(),
      );
      await _expenseRepo.update(updatedExpense);
      _error = '';
    } catch (e) {
      _error = 'Failed to update expense: $e';
    }
    _setLoading(false);
  }

  void setFilterMode(String mode) {
    _filterMode = mode;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    _customStartDate = start;
    _customEndDate = end;
    _filterMode = 'custom';
    notifyListeners();
  }

  /// Watch expenses from Firestore
  void _watchExpenses() {
    _expenseRepo.watch().listen(
      (expenses) {
        _expenses = expenses;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load expenses: $error';
        notifyListeners();
      },
    );
  }

  /// Legacy method for Hive (deprecated)
  Future<void> _loadExpenses() async {
    _setLoading(true);
    try {
      // TODO(CURSOR): This is deprecated, use _watchExpenses() instead
      _error = '';
    } catch (e) {
      _error = 'Failed to load expenses: $e';
    }
    _setLoading(false);
  }

  Future<void> addExpenseFromText(String text) async {
    _setLoading(true);
    try {
      final expenseData = await _aiService.processExpenseInput(text);
      final expense = Expense(
        id: const Uuid().v4(),
        category: expenseData['category'],
        amount: expenseData['amount'],
        description: expenseData['description'],
        dateTime: DateTime.now(),
      );

      await _expenseRepo.add(expense);
      _error = '';
    } catch (e) {
      _error = 'Failed to process expense: $e';
    }
    _setLoading(false);
  }

  Future<void> addExpenseFromTextLocal(String text) async {
    _setLoading(true);
    try {
      final expenseData = AdaptiveExpenseParser.parseExpenseInput(text);
      final expense = Expense(
        id: const Uuid().v4(),
        category: expenseData['category'],
        amount: expenseData['amount'],
        description: expenseData['description'],
        dateTime: DateTime.now(),
      );

      await _expenseRepo.add(expense);
      _error = '';
    } catch (e) {
      _error = 'Failed to process expense: $e';
    }
    _setLoading(false);
  }

  // Add method to handle category corrections
  Future<void> correctExpenseCategory(
      String originalText, String newCategory) async {
    await AdaptiveExpenseParser.learnFromCorrection(originalText, newCategory);
  }

  List<Expense> _filterExpenses() {
    if (_filterMode == 'custom' &&
        _customStartDate != null &&
        _customEndDate != null) {
      return _expenses
          .where((expense) =>
              expense.dateTime.isAfter(_customStartDate!) &&
              expense.dateTime
                  .isBefore(_customEndDate!.add(const Duration(days: 1))))
          .toList();
    }
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (_filterMode) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case 'yearly':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
    }

    return _expenses
        .where((expense) =>
            expense.dateTime.isAfter(startDate) &&
            expense.dateTime.isBefore(endDate))
        .toList();
  }

  double _calculateTotal() {
    return _filterExpenses().fold(0, (sum, expense) => sum + expense.amount);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
