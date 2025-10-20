import '../hive/expense.dart';

abstract class ExpenseRepo {
  Future<void> addExpense(Expense expense);
  Future<void> updateExpense(String id, Expense expense);
  Future<void> deleteExpense(String id);
  Stream<List<Expense>> watchExpenses();
  Future<List<Expense>> getExpenses();
}
