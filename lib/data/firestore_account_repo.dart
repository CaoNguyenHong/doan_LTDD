import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account.dart';

class FirestoreAccountRepo {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreAccountRepo({required this.uid});

  String get _collectionPath => 'users/$uid/accounts';

  Stream<List<Account>> watchAccounts() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Account.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addAccount(Account account) async {
    await _firestore
        .collection(_collectionPath)
        .doc(account.id)
        .set(account.toMap());
  }

  Future<void> updateAccount(String accountId, Account account) async {
    await _firestore
        .collection(_collectionPath)
        .doc(accountId)
        .update(account.toMap());
  }

  Future<void> deleteAccount(String accountId) async {
    await _firestore.collection(_collectionPath).doc(accountId).delete();
  }

  Future<Account?> getAccount(String accountId) async {
    final doc =
        await _firestore.collection(_collectionPath).doc(accountId).get();
    if (doc.exists) {
      return Account.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<void> setDefaultAccount(String accountId) async {
    // Remove default from all accounts
    final batch = _firestore.batch();
    final accounts = await _firestore.collection(_collectionPath).get();

    for (var doc in accounts.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }

    // Set new default
    batch.update(
      _firestore.collection(_collectionPath).doc(accountId),
      {'isDefault': true, 'updatedAt': Timestamp.now()},
    );

    await batch.commit();
  }

  Future<Account?> getDefaultAccount() async {
    final query = await _firestore
        .collection(_collectionPath)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return Account.fromMap(doc.id, doc.data());
    }
    return null;
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    await _firestore.collection(_collectionPath).doc(accountId).update({
      'balance': newBalance,
      'updatedAt': Timestamp.now(),
    });
  }
}
