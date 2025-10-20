import '../hive/expense.dart';
import '../service/expense_repo.dart';
import 'firestore_data_source.dart';

class FirestoreExpenseRepo implements ExpenseRepo {
  final String uid;
  final FirestoreDataSource _dataSource;

  FirestoreExpenseRepo({
    required this.uid,
    required FirestoreDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<void> addExpense(Expense expense) async {
    await _dataSource.addExpense(uid, expense);
  }

  @override
  Future<void> updateExpense(String id, Expense expense) async {
    await _dataSource.updateExpense(uid, id, expense);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _dataSource.deleteExpense(uid, id);
  }

  @override
  Stream<List<Expense>> watchExpenses() {
    return _dataSource.watchExpenses(uid).map((dataList) {
      return dataList.map((data) => Expense(
        id: data['id'] as String,
        category: data['category'] as String,
        amount: (data['amount'] as num).toDouble(),
        description: data['description'] as String,
        dateTime: data['dateTime'] as DateTime,
      )).toList();
    });
  }

  @override
  Future<List<Expense>> getExpenses() async {
    final dataList = await _dataSource.getExpenses(uid);
    return dataList.map((data) => Expense(
      id: data['id'] as String,
      category: data['category'] as String,
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] as String,
      dateTime: data['dateTime'] as DateTime,
    )).toList();
  }
}