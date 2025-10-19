import '../hive/expense.dart';
import 'firestore_data_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstract repository interface for expenses
abstract class ExpenseRepo {
  Stream<List<Expense>> watch({DateTime? from, DateTime? to});
  Future<void> add(Expense expense);
  Future<void> update(Expense expense);
  Future<void> remove(String id);
}

/// Firestore implementation of ExpenseRepo
class FirestoreExpenseRepo implements ExpenseRepo {
  final String uid;
  final FirestoreDataSource dataSource;

  FirestoreExpenseRepo({
    required this.uid,
    required this.dataSource,
  });

  @override
  Stream<List<Expense>> watch({DateTime? from, DateTime? to}) {
    return dataSource.watchExpenses(uid, from: from, to: to).map((rows) {
      return rows.map((data) => _mapToExpense(data)).toList();
    });
  }

  @override
  Future<void> add(Expense expense) async {
    await dataSource.addExpense(uid, {
      'category': expense.category,
      'amount': expense.amount,
      'description': expense.description,
      'dateTime': Timestamp.fromDate(expense.dateTime.toUtc()),
    });
  }

  @override
  Future<void> update(Expense expense) async {
    await dataSource.updateExpense(uid, expense.id, {
      'category': expense.category,
      'amount': expense.amount,
      'description': expense.description,
      'dateTime': Timestamp.fromDate(expense.dateTime.toUtc()),
    });
  }

  @override
  Future<void> remove(String id) async {
    await dataSource.softDeleteExpense(uid, id);
  }

  /// Convert Firestore data to Expense model
  Expense _mapToExpense(Map<String, dynamic> data) {
    return Expense(
      id: data['id'] as String,
      category: data['category'] as String,
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] as String,
      dateTime: (data['dateTime'] as Timestamp).toDate(),
    );
  }
}
