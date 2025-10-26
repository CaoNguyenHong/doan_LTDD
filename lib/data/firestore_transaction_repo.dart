import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart' as models;

class FirestoreTransactionRepo {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreTransactionRepo({required this.uid});

  String get _collectionPath => 'users/$uid/transactions';

  Stream<List<models.Transaction>> watchTransactions() {
    print('🔥 FirestoreTransactionRepo: Watching transactions for UID: $uid');
    print('🔥 FirestoreTransactionRepo: Collection path: $_collectionPath');

    return _firestore
        .collection(_collectionPath)
        .where('deleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      print(
          '🔥 FirestoreTransactionRepo: Received ${snapshot.docs.length} documents from Firestore');
      print(
          '🔥 FirestoreTransactionRepo: Snapshot metadata: ${snapshot.metadata}');

      final transactions = snapshot.docs.map((doc) {
        print(
            '🔥 FirestoreTransactionRepo: Document ID: ${doc.id}, Data: ${doc.data()}');
        return models.Transaction.fromMap(doc.id, doc.data());
      }).toList();

      // Sort manually to avoid index requirement
      transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      print(
          '🔥 FirestoreTransactionRepo: Returning ${transactions.length} transactions');
      return transactions;
    });
  }

  Stream<List<models.Transaction>> watchTransactionsByAccount(
      String accountId) {
    return _firestore
        .collection(_collectionPath)
        .where('accountId', isEqualTo: accountId)
        .where('deleted', isEqualTo: false)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => models.Transaction.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<models.Transaction>> watchTransactionsByCategory(
      String categoryId) {
    return _firestore
        .collection(_collectionPath)
        .where('categoryId', isEqualTo: categoryId)
        .where('deleted', isEqualTo: false)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => models.Transaction.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<models.Transaction>> watchTransactionsByDateRange(
      DateTime start, DateTime end) {
    return _firestore
        .collection(_collectionPath)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .where('deleted', isEqualTo: false)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => models.Transaction.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addTransaction(models.Transaction transaction) async {
    await _firestore
        .collection(_collectionPath)
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  Future<void> updateTransaction(
      String transactionId, models.Transaction transaction) async {
    await _firestore
        .collection(_collectionPath)
        .doc(transactionId)
        .update(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _firestore
        .collection(_collectionPath)
        .doc(transactionId)
        .update({'deleted': true, 'updatedAt': Timestamp.now()});
  }

  Future<models.Transaction?> getTransaction(String transactionId) async {
    final doc =
        await _firestore.collection(_collectionPath).doc(transactionId).get();
    if (doc.exists) {
      return models.Transaction.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<List<models.Transaction>> searchTransactions(String query) async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('deleted', isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => models.Transaction.fromMap(doc.id, doc.data()))
        .where((transaction) =>
            transaction.description
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            transaction.tags
                .any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  Future<List<models.Transaction>> getTransactionsByFilter({
    String? accountId,
    String? categoryId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<String>? tags,
    String? searchQuery,
  }) async {
    Query query = _firestore
        .collection(_collectionPath)
        .where('deleted', isEqualTo: false);

    if (accountId != null) {
      query = query.where('accountId', isEqualTo: accountId);
    }

    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    if (startDate != null) {
      query = query.where('dateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('dateTime',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    if (minAmount != null) {
      query = query.where('amount', isGreaterThanOrEqualTo: minAmount);
    }

    if (maxAmount != null) {
      query = query.where('amount', isLessThanOrEqualTo: maxAmount);
    }

    final snapshot = await query.orderBy('dateTime', descending: true).get();

    var transactions = snapshot.docs
        .map((doc) => models.Transaction.fromMap(
            doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    // Filter by tags and search query in memory
    if (tags != null && tags.isNotEmpty) {
      transactions = transactions
          .where((tx) => tx.tags.any((tag) => tags.contains(tag)))
          .toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      transactions = transactions
          .where((tx) =>
              tx.description
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              tx.tags.any((tag) =>
                  tag.toLowerCase().contains(searchQuery.toLowerCase())))
          .toList();
    }

    return transactions;
  }
}
