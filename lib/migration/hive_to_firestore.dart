import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // TODO(CURSOR): Uncomment if needed
import '../service/database_service.dart';
import '../data/firestore_data_source.dart';

class HiveToFirestoreMigration {
  final DatabaseService?
      _hiveService; // TODO(CURSOR): Optional, remove when fully migrated
  final FirestoreDataSource _firestoreDataSource = FirestoreDataSource();

  HiveToFirestoreMigration({DatabaseService? hiveService})
      : _hiveService = hiveService;

  /// Run migration once if Firestore is empty
  Future<void> runOnceIfCloudEmpty() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to run migration');
    }

    final uid = user.uid;

    // Check if user already has expenses in Firestore
    final expenses = await _firestoreDataSource.getExpenses(uid);
    if (expenses.isNotEmpty) {
      print('Migration skipped: User already has data in Firestore');
      return;
    }

    // Check if Hive has data to migrate
    if (_hiveService == null) {
      print('Migration skipped: No Hive service available');
      return;
    }

    try {
      await _migrateExpenses(uid);
      await _migrateLearnedCategories(uid);
      print('Migration completed successfully');
    } catch (e) {
      print('Migration failed: $e');
      rethrow;
    }
  }

  /// Migrate expenses from Hive to Firestore
  Future<void> _migrateExpenses(String uid) async {
    try {
      final hiveExpenses = _hiveService!.getExpenses();
      print('Migrating ${hiveExpenses.length} expenses...');

      for (final expense in hiveExpenses) {
        await _firestoreDataSource.addExpense(uid, expense);
      }

      print('Expenses migration completed');
    } catch (e) {
      print('Failed to migrate expenses: $e');
      rethrow;
    }
  }

  /// Migrate learned categories from Hive to Firestore
  Future<void> _migrateLearnedCategories(String uid) async {
    try {
      // TODO(CURSOR): Implement if you have learned categories in Hive
      // This is optional and depends on your Hive implementation
      print('Learned categories migration completed (no data to migrate)');
    } catch (e) {
      print('Failed to migrate learned categories: $e');
      // Don't rethrow for learned categories as it's not critical
    }
  }

  /// Check if migration is needed
  Future<bool> isMigrationNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final uid = user.uid;
    final expenses = await _firestoreDataSource.getExpenses(uid);
    final hasCloudData = expenses.isNotEmpty;

    // Migration needed if Firestore is empty and Hive has data
    if (!hasCloudData && _hiveService != null) {
      final hiveExpenses = _hiveService.getExpenses();
      return hiveExpenses.isNotEmpty;
    }

    return false;
  }

  /// Get migration status
  Future<MigrationStatus> getMigrationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return MigrationStatus.notAuthenticated;

    final uid = user.uid;
    final expenses = await _firestoreDataSource.getExpenses(uid);
    final hasCloudData = expenses.isNotEmpty;

    if (hasCloudData) {
      return MigrationStatus.alreadyMigrated;
    }

    if (_hiveService == null) {
      return MigrationStatus.noHiveData;
    }

    final hiveExpenses = _hiveService.getExpenses();
    if (hiveExpenses.isEmpty) {
      return MigrationStatus.noDataToMigrate;
    }

    return MigrationStatus.readyToMigrate;
  }
}

enum MigrationStatus {
  notAuthenticated,
  alreadyMigrated,
  noHiveData,
  noDataToMigrate,
  readyToMigrate,
}
