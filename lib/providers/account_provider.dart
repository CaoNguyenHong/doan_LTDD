import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../data/firestore_account_repo.dart';
import '../utils/sample_data.dart';

class AccountProvider with ChangeNotifier {
  final String uid;
  final FirestoreAccountRepo _accountRepo;

  List<Account> _accounts = [];
  bool _isLoading = false;
  String _error = '';

  AccountProvider({required this.uid})
      : _accountRepo = FirestoreAccountRepo(uid: uid) {
    _watchAccounts();
  }

  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String get error => _error;

  void _watchAccounts() {
    _setLoading(true);
    _accountRepo.watchAccounts().listen(
      (accounts) {
        _accounts = accounts;

        // Create sample data if no accounts exist
        if (_accounts.isEmpty) {
          _createSampleData();
        }

        _error = '';
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        _error = 'Không thể tải danh sách ví: $error';
        _setLoading(false);
        notifyListeners();
      },
    );
  }

  Future<void> _createSampleData() async {
    try {
      final sampleAccounts = SampleData.getDefaultAccounts();
      for (final account in sampleAccounts) {
        await _accountRepo.addAccount(account);
      }
    } catch (e) {
      print('Error creating sample data: $e');
    }
  }

  Future<void> addAccount(Account account) async {
    _setLoading(true);
    try {
      await _accountRepo.addAccount(account);
      _error = '';
    } catch (e) {
      _error = 'Không thể thêm ví: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> updateAccount(String accountId, Account account) async {
    _setLoading(true);
    try {
      await _accountRepo.updateAccount(accountId, account);
      _error = '';
    } catch (e) {
      _error = 'Không thể cập nhật ví: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> deleteAccount(String accountId) async {
    _setLoading(true);
    try {
      await _accountRepo.deleteAccount(accountId);
      _error = '';
    } catch (e) {
      _error = 'Không thể xóa ví: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> setDefaultAccount(String accountId) async {
    _setLoading(true);
    try {
      await _accountRepo.setDefaultAccount(accountId);
      _error = '';
    } catch (e) {
      _error = 'Không thể đặt ví mặc định: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    _setLoading(true);
    try {
      await _accountRepo.updateAccountBalance(accountId, newBalance);
      _error = '';
    } catch (e) {
      _error = 'Không thể cập nhật số dư: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Account? getDefaultAccount() {
    try {
      return _accounts.firstWhere((account) => account.isDefault);
    } catch (e) {
      return null;
    }
  }

  Account? getAccountById(String accountId) {
    try {
      return _accounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }

  List<Account> getAccountsByType(String type) {
    return _accounts.where((account) => account.type == type).toList();
  }

  double getTotalBalance() {
    return _accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  double getTotalBalanceByType(String type) {
    return _accounts
        .where((account) => account.type == type)
        .fold(0.0, (sum, account) => sum + account.balance);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
