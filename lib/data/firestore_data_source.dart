import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDataSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get expenses collection reference for a user
  CollectionReference<Map<String, dynamic>> expensesRef(String uid) =>
      _db.collection('users').doc(uid).collection('expenses');

  /// Get settings document reference for a user
  DocumentReference<Map<String, dynamic>> settingsRef(String uid) =>
      _db.collection('users').doc(uid).collection('settings').doc('user_settings');

  /// Get learned categories collection reference for a user
  CollectionReference<Map<String, dynamic>> learnedRef(String uid) =>
      _db.collection('users').doc(uid).collection('learned');

  /// Watch expenses with optional date filtering
  Stream<List<Map<String, dynamic>>> watchExpenses(
    String uid, {
    DateTime? from,
    DateTime? to,
  }) {
    Query<Map<String, dynamic>> query = expensesRef(uid)
        .where('deleted', isEqualTo: false)
        .orderBy('dateTime', descending: true);

    if (from != null) {
      query = query.where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(from.toUtc()));
    }
    if (to != null) {
      query = query.where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(to.toUtc()));
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  /// Add a new expense
  Future<String> addExpense(String uid, Map<String, dynamic> data) async {
    final doc = expensesRef(uid).doc();
    await doc.set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': false,
    });
    return doc.id;
  }

  /// Update an existing expense
  Future<void> updateExpense(String uid, String expenseId, Map<String, dynamic> data) async {
    await expensesRef(uid).doc(expenseId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Soft delete an expense
  Future<void> softDeleteExpense(String uid, String expenseId) async {
    await expensesRef(uid).doc(expenseId).update({
      'deleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Watch user settings
  Stream<Map<String, dynamic>?> watchSettings(String uid) {
    return settingsRef(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
  }

  /// Update user settings
  Future<void> updateSettings(String uid, Map<String, dynamic> data) async {
    await settingsRef(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Watch learned categories
  Stream<List<Map<String, dynamic>>> watchLearnedCategories(String uid) {
    return learnedRef(uid)
        .orderBy('frequency', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  /// Add or update learned category
  Future<void> updateLearnedCategory(String uid, String word, String category, int frequency) async {
    await learnedRef(uid).doc(word).set({
      'category': category,
      'frequency': frequency,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Check if user has any expenses (for migration)
  Future<bool> hasExpenses(String uid) async {
    final snapshot = await expensesRef(uid).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  /// Get all expenses for migration
  Future<List<Map<String, dynamic>>> getAllExpenses(String uid) async {
    final snapshot = await expensesRef(uid)
        .where('deleted', isEqualTo: false)
        .get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }
}
