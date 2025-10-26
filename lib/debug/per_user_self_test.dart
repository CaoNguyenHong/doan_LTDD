import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/firestore_data_source.dart';

class PerUserSelfTest extends StatefulWidget {
  const PerUserSelfTest({super.key});

  @override
  State<PerUserSelfTest> createState() => _PerUserSelfTestState();
}

class _PerUserSelfTestState extends State<PerUserSelfTest> {
  final FirestoreDataSource _ds = FirestoreDataSource();
  String? _currentUid;
  List<Map<String, dynamic>> _testData = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _currentUid = user?.uid;
    });
  }

  Future<void> _createTestTransaction() async {
    if (_currentUid == null) return;

    setState(() {
      _loading = true;
    });

    try {
      await _ds.addTx(_currentUid!, {
        'type': 'expense',
        'categoryId': 'test-category',
        'amount': 100000.0,
        'description': 'Test transaction for user $_currentUid',
        'accountId': 'test-account',
        'dateTime': DateTime.now().toUtc(),
        'tags': ['test', 'debug'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Created test transaction for user: $_currentUid'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadTestData() async {
    if (_currentUid == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final transactions = await _ds.txRef(_currentUid!).get();
      setState(() {
        _testData = transactions.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _checkFirebaseStructure() async {
    if (_currentUid == null) return;

    try {
      // Check user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid!)
          .get();

      // Check transactions collection
      final transactions = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid!)
          .collection('transactions')
          .get();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Firebase Structure Check'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User UID: $_currentUid'),
              const SizedBox(height: 8),
              Text('User document exists: ${userDoc.exists}'),
              const SizedBox(height: 8),
              Text('Transactions count: ${transactions.docs.length}'),
              const SizedBox(height: 8),
              Text('Path: users/$_currentUid/transactions'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error checking structure: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Per-User Data Test'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current User Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('UID: ${_currentUid ?? 'Not logged in'}'),
                    Text(
                        'Email: ${FirebaseAuth.instance.currentUser?.email ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : _createTestTransaction,
                  child: const Text('Create Test Transaction'),
                ),
                ElevatedButton(
                  onPressed: _loading ? null : _loadTestData,
                  child: const Text('Load Test Data'),
                ),
                ElevatedButton(
                  onPressed: _checkFirebaseStructure,
                  child: const Text('Check Firebase Structure'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _testData.isEmpty
                      ? const Center(
                          child: Text(
                            'No test data found.\nTap "Load Test Data" to refresh.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _testData.length,
                          itemBuilder: (context, index) {
                            final data = _testData[index];
                            return Card(
                              child: ListTile(
                                title: Text(
                                    data['description'] ?? 'No description'),
                                subtitle: Text(
                                  'Amount: ${data['amount']} | Type: ${data['type']}',
                                ),
                                trailing: Text(
                                  'ID: ${data['id']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}


