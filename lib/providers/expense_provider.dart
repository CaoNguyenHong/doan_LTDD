import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:spend_sage/service/api_service.dart';
import 'package:spend_sage/service/adaptive_expense_parser.dart';
import 'package:spend_sage/service/expense_repo.dart';
import 'package:spend_sage/data/firestore_data_source.dart';
import 'package:spend_sage/data/firestore_expense_repo.dart';
import 'package:spend_sage/data/firestore_transaction_repo.dart';
import 'package:spend_sage/models/transaction.dart' as models;
import 'package:spend_sage/utils/transaction_converter.dart';
import 'package:spend_sage/service/currency_service.dart';
import 'package:uuid/uuid.dart';

class ExpenseProvider with ChangeNotifier {
  ExpenseRepo? _expenseRepo;
  FirestoreTransactionRepo? _transactionRepo;
  List<Expense> _expenses = [];
  String _filterMode = 'daily';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String _error = '';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  /// Factory constructor for Firestore
  ExpenseProvider.firestore() {
    _initializeWithCurrentUser();
  }

  /// Initialize with current user
  void _initializeWithCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'demo-user';

    print('💰 ExpenseProvider: Initializing with user UID: $uid');

    // Initialize both repos
    _expenseRepo = FirestoreExpenseRepo(
      uid: uid,
      dataSource: FirestoreDataSource(),
    );

    _transactionRepo = FirestoreTransactionRepo(uid: uid);

    // Only watch transactions (main data source)
    _watchTransactions();
  }

  /// Update user when authentication state changes
  void updateUser() {
    print('💰 ExpenseProvider: Updating user...');
    // Clear old expenses before switching user
    _expenses = [];
    _error = '';

    // Only reinitialize if not already initialized
    if (_transactionRepo == null) {
      _initializeWithCurrentUser();
    }
    notifyListeners();
  }

  /// Convert all expenses to new currency
  Future<void> convertExpensesToCurrency(
      String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return;

    try {
      final exchangeRate =
          await CurrencyService.getExchangeRate(fromCurrency, toCurrency);
      print(
          '💰 ExpenseProvider: Converting expenses from $fromCurrency to $toCurrency with rate: $exchangeRate');

      for (var expense in _expenses) {
        final convertedAmount = expense.amount * exchangeRate;
        final updatedExpense = Expense(
          id: expense.id,
          category: expense.category,
          amount: convertedAmount,
          description: expense.description,
          dateTime: expense.dateTime,
        );
        await _expenseRepo?.updateExpense(expense.id, updatedExpense);
      }

      print(
          '💰 ExpenseProvider: Successfully converted ${_expenses.length} expenses');
    } catch (e) {
      print('💰 ExpenseProvider: Error converting expenses: $e');
    }
  }

  /// Legacy constructor for Hive (deprecated)
  ExpenseProvider({
    required dynamic
        databaseService, // TODO(CURSOR): Remove when fully migrated
    required AIService aiService,
  }) {
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
      // Delete from transactions first (main data source)
      if (_transactionRepo != null) {
        try {
          await _transactionRepo!.deleteTransaction(id);
          print('💰 ExpenseProvider: Transaction deleted successfully: $id');
        } catch (e) {
          print('💰 ExpenseProvider: Transaction not found: $e');
        }
      }

      // Also try to delete from expenses collection (legacy)
      if (_expenseRepo != null) {
        try {
          await _expenseRepo!.deleteExpense(id);
          print('💰 ExpenseProvider: Expense deleted successfully: $id');
        } catch (e) {
          print('💰 ExpenseProvider: Expense not found (legacy): $e');
        }
      }

      print('💰 ExpenseProvider: Delete operation completed for: $id');
      _error = '';
    } catch (e) {
      print('💰 ExpenseProvider: Error deleting expense: $e');
      _error = 'Không thể xóa chi tiêu: $e';
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
      // Update in transactions collection first (main data source)
      if (_transactionRepo != null) {
        try {
          // Get existing transaction first
          final existingTransaction =
              await _transactionRepo!.getTransaction(id);
          if (existingTransaction != null) {
            // Update the transaction
            final updatedTransaction = existingTransaction.copyWith(
              description: description,
              amount: amount,
              categoryId: _mapCategoryToId(category),
              updatedAt: DateTime.now(),
            );
            await _transactionRepo!.updateTransaction(id, updatedTransaction);
            print('💰 ExpenseProvider: Transaction updated successfully: $id');
          }
        } catch (e) {
          print('💰 ExpenseProvider: Transaction not found: $e');
        }
      }

      // Also try to update in expenses collection (legacy)
      if (_expenseRepo != null) {
        try {
          final updatedExpense = Expense(
            id: id,
            category: category,
            amount: amount,
            description: description,
            dateTime: DateTime.now(),
          );
          await _expenseRepo!.updateExpense(updatedExpense.id, updatedExpense);
          print('💰 ExpenseProvider: Expense updated successfully: $id');
        } catch (e) {
          print('💰 ExpenseProvider: Expense not found (legacy): $e');
        }
      }

      print('💰 ExpenseProvider: Update operation completed for: $id');
      _error = '';
    } catch (e) {
      print('💰 ExpenseProvider: Error updating expense: $e');
      _error = 'Không thể cập nhật chi tiêu: $e';
    }
    _setLoading(false);
  }

  /// Map category name to category ID
  String _mapCategoryToId(String categoryName) {
    // If category already has emoji, extract the ID
    if (categoryName.contains('🍽️') || categoryName.contains('Ăn uống')) {
      return 'food';
    } else if (categoryName.contains('🚗') ||
        categoryName.contains('Giao thông')) {
      return 'transport';
    } else if (categoryName.contains('💡') ||
        categoryName.contains('Tiện ích')) {
      return 'utilities';
    } else if (categoryName.contains('🏥') ||
        categoryName.contains('Sức khỏe')) {
      return 'health';
    } else if (categoryName.contains('📚') ||
        categoryName.contains('Giáo dục')) {
      return 'education';
    } else if (categoryName.contains('🛍️') ||
        categoryName.contains('Mua sắm')) {
      return 'shopping';
    } else if (categoryName.contains('🎬') ||
        categoryName.contains('Giải trí')) {
      return 'entertainment';
    } else if (categoryName.contains('📝') || categoryName.contains('Khác')) {
      return 'other';
    }

    // If category is already an ID, return as is
    switch (categoryName.toLowerCase()) {
      case 'food':
        return 'food';
      case 'transport':
        return 'transport';
      case 'utilities':
        return 'utilities';
      case 'health':
        return 'health';
      case 'education':
        return 'education';
      case 'shopping':
        return 'shopping';
      case 'entertainment':
        return 'entertainment';
      case 'salary':
        return 'salary';
      case 'investment':
        return 'investment';
      case 'other':
      default:
        return 'other';
    }
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
    if (_expenseRepo == null) return;

    print('💰 ExpenseProvider: Starting to watch expenses...');
    _setLoading(true);

    _expenseRepo!.watchExpenses().listen(
      (expenses) {
        print('💰 ExpenseProvider: Received ${expenses.length} expenses');
        _expenses = expenses;
        _error = '';
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        print('💰 ExpenseProvider: Error watching expenses: $error');
        _error = 'Không thể tải chi tiêu: $error';
        _setLoading(false);
        notifyListeners();
      },
    );
  }

  /// Watch transactions from Firestore
  void _watchTransactions() {
    if (_transactionRepo == null) {
      print(
          '💰 ExpenseProvider: _transactionRepo is null, skipping _watchTransactions');
      return;
    }

    print(
        '💰 ExpenseProvider: Starting to watch transactions from Firestore...');
    print('💰 ExpenseProvider: User UID = ${_transactionRepo!.uid}');

    try {
      _transactionRepo!.watchTransactions().listen(
        (transactions) {
          print(
              '💰 ExpenseProvider: Received ${transactions.length} transactions from Firestore');
          print(
              '💰 ExpenseProvider: Transaction details: ${transactions.map((t) => '${t.type}: ${t.description}').toList()}');

          // Convert transactions to expenses
          final transactionExpenses = transactions
              .where((t) => t.type == 'expense') // Only show expenses
              .map((t) => TransactionConverter.transactionToExpense(t))
              .toList();

          // Replace expenses with transaction expenses
          _expenses = transactionExpenses;
          _expenses.sort(
              (a, b) => b.dateTime.compareTo(a.dateTime)); // Sort by date desc

          print(
              '💰 ExpenseProvider: Updated expenses list with ${_expenses.length} items');
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          print('💰 ExpenseProvider: Error watching transactions: $error');
          _error = 'Không thể tải dữ liệu: $error';
          _setLoading(false);
          notifyListeners();
        },
        cancelOnError: false, // Don't cancel on error
      );
    } catch (e) {
      print('💰 ExpenseProvider: Exception in _watchTransactions: $e');
      _error = 'Lỗi khởi tạo: $e';
      _setLoading(false);
      notifyListeners();
    }
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

  /// Add expense directly without parsing
  Future<void> addExpense(Expense expense) async {
    print(
        '💰 ExpenseProvider: Adding expense directly: ${expense.description}');
    _setLoading(true);
    try {
      await _expenseRepo!.addExpense(expense);
      print('💰 ExpenseProvider: Expense added successfully');
      _error = '';
    } catch (e) {
      print('💰 ExpenseProvider: Error adding expense: $e');
      _error = 'Không thể thêm chi tiêu: $e';
    }
    _setLoading(false);
  }

  Future<void> addExpenseFromText(String text) async {
    print('💰 ExpenseProvider: Starting addExpenseFromText with: $text');
    _setLoading(true);
    try {
      // Use local parser instead of AI (more reliable)
      final expenseData = AdaptiveExpenseParser.parseExpenseInput(text);
      print('💰 ExpenseProvider: Local parser processed data: $expenseData');

      final expense = Expense(
        id: const Uuid().v4(),
        category: expenseData['category'],
        amount: expenseData['amount'],
        description: expenseData['description'],
        dateTime: DateTime.now(),
      );

      print(
          '💰 ExpenseProvider: Created expense: ${expense.category}, ${expense.amount}, ${expense.description}');
      await _expenseRepo!.addExpense(expense);
      print('💰 ExpenseProvider: Expense added to repository successfully');
      _error = '';
    } catch (e) {
      print('💰 ExpenseProvider: Error adding expense: $e');
      _error = 'Không thể xử lý chi tiêu: $e';
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

      await _expenseRepo!.addExpense(expense);
      _error = '';
    } catch (e) {
      _error = 'Không thể xử lý chi tiêu: $e';
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
