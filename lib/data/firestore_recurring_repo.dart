import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recurring.dart';

class FirestoreRecurringRepo {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreRecurringRepo({required this.uid});

  String get _collectionPath => 'users/$uid/recurrings';

  Stream<List<Recurring>> watchRecurrings() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('nextRun', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recurring.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Recurring>> watchActiveRecurrings() {
    return _firestore
        .collection(_collectionPath)
        .where('active', isEqualTo: true)
        .orderBy('nextRun', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recurring.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addRecurring(Recurring recurring) async {
    await _firestore
        .collection(_collectionPath)
        .doc(recurring.id)
        .set(recurring.toMap());
  }

  Future<void> updateRecurring(String recurringId, Recurring recurring) async {
    await _firestore
        .collection(_collectionPath)
        .doc(recurringId)
        .update(recurring.toMap());
  }

  Future<void> deleteRecurring(String recurringId) async {
    await _firestore.collection(_collectionPath).doc(recurringId).delete();
  }

  Future<Recurring?> getRecurring(String recurringId) async {
    final doc =
        await _firestore.collection(_collectionPath).doc(recurringId).get();
    if (doc.exists) {
      return Recurring.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<void> toggleRecurring(String recurringId, bool active) async {
    await _firestore.collection(_collectionPath).doc(recurringId).update({
      'active': active,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateNextRun(String recurringId, DateTime nextRun) async {
    await _firestore.collection(_collectionPath).doc(recurringId).update({
      'nextRun': Timestamp.fromDate(nextRun),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<List<Recurring>> getDueRecurrings() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('active', isEqualTo: true)
        .where('nextRun', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    return snapshot.docs
        .map((doc) => Recurring.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<Recurring>> getUpcomingRecurrings() async {
    final now = DateTime.now();
    final endOfWeek = now.add(const Duration(days: 7));

    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('active', isEqualTo: true)
        .where('nextRun', isGreaterThan: Timestamp.fromDate(now))
        .where('nextRun', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
        .get();

    return snapshot.docs
        .map((doc) => Recurring.fromMap(doc.id, doc.data()))
        .toList();
  }
}
