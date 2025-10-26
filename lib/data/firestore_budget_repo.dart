import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget.dart';

class FirestoreBudgetRepo {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreBudgetRepo({required this.uid});

  String get _collectionPath => 'users/$uid/budgets';

  Stream<List<Budget>> watchBudgets() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Budget.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Budget>> watchBudgetsByMonth(String month) {
    return _firestore
        .collection(_collectionPath)
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Budget.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addBudget(Budget budget) async {
    await _firestore
        .collection(_collectionPath)
        .doc(budget.id)
        .set(budget.toMap());
  }

  Future<void> updateBudget(String budgetId, Budget budget) async {
    await _firestore
        .collection(_collectionPath)
        .doc(budgetId)
        .update(budget.toMap());
  }

  Future<void> deleteBudget(String budgetId) async {
    await _firestore.collection(_collectionPath).doc(budgetId).delete();
  }

  Future<Budget?> getBudget(String budgetId) async {
    final doc =
        await _firestore.collection(_collectionPath).doc(budgetId).get();
    if (doc.exists) {
      return Budget.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<void> updateBudgetSpent(String budgetId, double spent) async {
    await _firestore.collection(_collectionPath).doc(budgetId).update({
      'spent': spent,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<List<Budget>> getBudgetsByPeriod(String period) async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('period', isEqualTo: period)
        .orderBy('month', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Budget.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<Budget>> getBudgetsByCategory(String categoryId) async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('month', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Budget.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<Budget>> getOverBudgetBudgets() async {
    final snapshot = await _firestore.collection(_collectionPath).get();

    return snapshot.docs
        .map((doc) => Budget.fromMap(doc.id, doc.data()))
        .where((budget) => budget.isOverBudget)
        .toList();
  }

  Future<List<Budget>> getNearLimitBudgets() async {
    final snapshot = await _firestore.collection(_collectionPath).get();

    return snapshot.docs
        .map((doc) => Budget.fromMap(doc.id, doc.data()))
        .where((budget) => budget.isNearLimit)
        .toList();
  }
}
