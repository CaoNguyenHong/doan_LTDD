import 'package:hive_flutter/hive_flutter.dart';
import 'package:spend_sage/constants.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:spend_sage/hive/learned_category.dart';

class DatabaseService {
  late Box<Expense> expenseBox;
  static late Box<LearnedCategory> learnedCategoriesBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ExpenseAdapter());
    expenseBox = await Hive.openBox<Expense>(Constants.expenseBoxName);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LearnedCategoryAdapter());
    }
    learnedCategoriesBox =
        await Hive.openBox<LearnedCategory>(Constants.learnedCategoriesBoxName);
  }

  Future<void> addExpense(Expense expense) async {
    await expenseBox.put(expense.id, expense);
  }

  List<Expense> getExpenses() {
    return expenseBox.values.toList();
  }

  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return expenseBox.values
        .where((expense) =>
            expense.dateTime.isAfter(start) && expense.dateTime.isBefore(end))
        .toList();
  }

  Future<void> deleteExpense(String id) async {
    await expenseBox.delete(id);
  }

  Future<void> updateExpense(Expense expense) async {
    await expenseBox.put(expense.id, expense);
  }
}
