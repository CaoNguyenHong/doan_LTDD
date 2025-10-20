import 'package:cloud_firestore/cloud_firestore.dart';
import '../hive/expense.dart';

class FirestoreDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add expense to Firestore
  Future<void> addExpense(String uid, Expense expense) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .add({
      'category': expense.category,
      'amount': expense.amount,
      'description': expense.description,
      'dateTime': Timestamp.fromDate(expense.dateTime),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': false,
    });
  }

  /// Update expense in Firestore
  Future<void> updateExpense(String uid, String expenseId, Expense expense) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(expenseId)
        .update({
      'category': expense.category,
      'amount': expense.amount,
      'description': expense.description,
      'dateTime': Timestamp.fromDate(expense.dateTime),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete expense (soft delete)
  Future<void> deleteExpense(String uid, String expenseId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(expenseId)
        .update({
      'deleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Watch expenses stream
  Stream<List<Map<String, dynamic>>> watchExpenses(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .where('deleted', isEqualTo: false)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'category': data['category'],
          'amount': data['amount'],
          'description': data['description'],
          'dateTime': (data['dateTime'] as Timestamp).toDate(),
          'createdAt': (data['createdAt'] as Timestamp).toDate(),
          'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
        };
      }).toList();
    });
  }

  /// Get expenses (one-time)
  Future<List<Map<String, dynamic>>> getExpenses(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .where('deleted', isEqualTo: false)
        .orderBy('dateTime', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'category': data['category'],
        'amount': data['amount'],
        'description': data['description'],
        'dateTime': (data['dateTime'] as Timestamp).toDate(),
        'createdAt': (data['createdAt'] as Timestamp).toDate(),
        'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
      };
    }).toList();
  }

  /// Add user settings
  Future<void> addUserSettings(String uid, Map<String, dynamic> settings) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('user_settings')
        .set({
      ...settings,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user settings
  Future<Map<String, dynamic>?> getUserSettings(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('user_settings')
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return {
      'currency': data['currency'],
      'darkMode': data['darkMode'],
      'userName': data['userName'],
      'dailyLimit': data['dailyLimit'],
      'weeklyLimit': data['weeklyLimit'],
      'monthlyLimit': data['monthlyLimit'],
      'yearlyLimit': data['yearlyLimit'],
      'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
    };
  }

  /// Add learned category
  Future<void> addLearnedCategory(String uid, String word, String category) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('learned')
        .doc(word)
        .set({
      'category': category,
      'frequency': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get learned categories
  Future<Map<String, String>> getLearnedCategories(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('learned')
        .get();

    final Map<String, String> learned = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      learned[doc.id] = data['category'] as String;
    }
    return learned;
  }

  /// Watch user settings stream
  Stream<Map<String, dynamic>?> watchSettings(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('user_settings')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      final data = snapshot.data()!;
      return {
        'currency': data['currency'],
        'darkMode': data['darkMode'],
        'userName': data['userName'],
        'dailyLimit': data['dailyLimit'],
        'weeklyLimit': data['weeklyLimit'],
        'monthlyLimit': data['monthlyLimit'],
        'yearlyLimit': data['yearlyLimit'],
        'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
      };
    });
  }

  /// Update user settings
  Future<void> updateSettings(String uid, Map<String, dynamic> settings) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('user_settings')
        .set({
      ...settings,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}