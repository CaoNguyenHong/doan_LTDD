import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDataSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User document reference ---
  DocumentReference<Map<String, dynamic>> userDocRef(String uid) =>
      _db.collection('users').doc(uid);

  // --- Transactions ---
  CollectionReference<Map<String, dynamic>> txRef(String uid) =>
      userDocRef(uid).collection('transactions');

  Stream<List<Map<String, dynamic>>> watchTx(String uid,
      {DateTime? from, DateTime? to}) {
    Query<Map<String, dynamic>> q = txRef(uid)
        .where('deleted', isEqualTo: false)
        .orderBy('dateTime', descending: true);
    if (from != null)
      q = q.where('dateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from.toUtc()));
    if (to != null)
      q = q.where('dateTime',
          isLessThanOrEqualTo: Timestamp.fromDate(to.toUtc()));
    return q
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> addTx(String uid, Map<String, dynamic> data) {
    final now = DateTime.now();
    return txRef(uid).doc().set({
      'type': data['type'] ?? 'expense',
      'amount': data['amount'] ?? 0,
      'accountId': data['accountId'] ?? '',
      'toAccountId': data['toAccountId'],
      'categoryId': data['categoryId'],
      'currency': data['currency'] ?? 'USD',
      'description': data['description'] ?? '',
      'merchantId': data['merchantId'],
      'tags': data['tags'] ?? [],
      'attachmentUrl': data['attachmentUrl'],
      'isAdjustment': data['isAdjustment'] ?? false,
      'deleted': false,

      // dateTime hiển thị ngay lập tức (không chờ serverTimestamp)
      'dateTime': (data['dateTime'] is DateTime)
          ? Timestamp.fromDate((data['dateTime'] as DateTime).toUtc())
          : Timestamp.fromDate(now.toUtc()),

      // audit fields vẫn dùng server clock
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTx(String uid, String id, Map<String, dynamic> data) =>
      txRef(uid).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> softDeleteTx(String uid, String id) => txRef(uid)
      .doc(id)
      .update({'deleted': true, 'updatedAt': FieldValue.serverTimestamp()});

  // --- Accounts ---
  CollectionReference<Map<String, dynamic>> accRef(String uid) =>
      userDocRef(uid).collection('accounts');

  Stream<List<Map<String, dynamic>>> watchAccounts(String uid) => accRef(uid)
      .where('deleted', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());

  Future<void> addAccount(String uid, Map<String, dynamic> data) =>
      accRef(uid).doc().set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deleted': false,
      });

  Future<void> updateAccount(
          String uid, String id, Map<String, dynamic> data) =>
      accRef(uid).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> softDeleteAccount(String uid, String id) => accRef(uid)
      .doc(id)
      .update({'deleted': true, 'updatedAt': FieldValue.serverTimestamp()});

  // --- Budgets ---
  CollectionReference<Map<String, dynamic>> budgetRef(String uid) =>
      userDocRef(uid).collection('budgets');

  Stream<List<Map<String, dynamic>>> watchBudgets(String uid) => budgetRef(uid)
      .where('deleted', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());

  Future<void> addBudget(String uid, Map<String, dynamic> data) =>
      budgetRef(uid).doc().set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deleted': false,
      });

  Future<void> updateBudget(String uid, String id, Map<String, dynamic> data) =>
      budgetRef(uid).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> softDeleteBudget(String uid, String id) => budgetRef(uid)
      .doc(id)
      .update({'deleted': true, 'updatedAt': FieldValue.serverTimestamp()});

  // --- Recurring Transactions ---
  CollectionReference<Map<String, dynamic>> recurringRef(String uid) =>
      _db.collection('users').doc(uid).collection('recurring');

  Stream<List<Map<String, dynamic>>> watchRecurring(String uid) =>
      recurringRef(uid)
          .where('deleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());

  Future<void> addRecurring(String uid, Map<String, dynamic> data) =>
      recurringRef(uid).doc().set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deleted': false,
      });

  Future<void> updateRecurring(
          String uid, String id, Map<String, dynamic> data) =>
      recurringRef(uid).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> softDeleteRecurring(String uid, String id) => recurringRef(uid)
      .doc(id)
      .update({'deleted': true, 'updatedAt': FieldValue.serverTimestamp()});

  // --- User Settings ---
  DocumentReference<Map<String, dynamic>> settingsRef(String uid) =>
      _db.collection('users').doc(uid).collection('settings').doc('main');

  Stream<Map<String, dynamic>?> watchSettings(String uid) =>
      settingsRef(uid).snapshots().map((s) => s.exists ? s.data() : null);

  Future<void> updateSettings(String uid, Map<String, dynamic> data) =>
      settingsRef(uid).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  // --- Legacy Expense Support (for backward compatibility) ---
  CollectionReference<Map<String, dynamic>> expenseRef(String uid) =>
      _db.collection('users').doc(uid).collection('expenses');

  Stream<List<Map<String, dynamic>>> watchExpenses(String uid) =>
      expenseRef(uid)
          .where('deleted', isEqualTo: false)
          .orderBy('dateTime', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());

  Future<void> addExpense(String uid, Map<String, dynamic> data) =>
      expenseRef(uid).doc().set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deleted': false,
      });

  Future<void> updateExpense(
          String uid, String id, Map<String, dynamic> data) =>
      expenseRef(uid).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> softDeleteExpense(String uid, String id) => expenseRef(uid)
      .doc(id)
      .update({'deleted': true, 'updatedAt': FieldValue.serverTimestamp()});

  // --- Learned Categories ---
  CollectionReference<Map<String, dynamic>> learnedRef(String uid) =>
      _db.collection('users').doc(uid).collection('learned');

  Stream<List<Map<String, dynamic>>> watchLearned(String uid) => learnedRef(uid)
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());

  Future<void> addLearned(String uid, Map<String, dynamic> data) =>
      learnedRef(uid).doc().set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateLearned(
          String uid, String id, Map<String, dynamic> data) =>
      learnedRef(uid).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteLearned(String uid, String id) =>
      learnedRef(uid).doc(id).delete();
}
