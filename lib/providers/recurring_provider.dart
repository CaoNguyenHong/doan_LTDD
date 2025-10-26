import 'package:flutter/foundation.dart';
import '../models/recurring.dart';
import '../data/firestore_recurring_repo.dart';

class RecurringProvider with ChangeNotifier {
  final String uid;
  final FirestoreRecurringRepo _recurringRepo;

  List<Recurring> _recurrings = [];
  bool _isLoading = false;
  String _error = '';

  RecurringProvider({required this.uid})
      : _recurringRepo = FirestoreRecurringRepo(uid: uid) {
    _watchRecurrings();
  }

  List<Recurring> get recurrings => _recurrings;
  bool get isLoading => _isLoading;
  String get error => _error;

  void _watchRecurrings() {
    _setLoading(true);
    _recurringRepo.watchRecurrings().listen(
      (recurrings) {
        _recurrings = recurrings;
        _error = '';
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        _error = 'Không thể tải danh sách giao dịch định kỳ: $error';
        _setLoading(false);
        notifyListeners();
      },
    );
  }

  Future<void> addRecurring(Recurring recurring) async {
    _setLoading(true);
    try {
      await _recurringRepo.addRecurring(recurring);
      _error = '';
    } catch (e) {
      _error = 'Không thể thêm giao dịch định kỳ: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> updateRecurring(String recurringId, Recurring recurring) async {
    _setLoading(true);
    try {
      await _recurringRepo.updateRecurring(recurringId, recurring);
      _error = '';
    } catch (e) {
      _error = 'Không thể cập nhật giao dịch định kỳ: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> deleteRecurring(String recurringId) async {
    _setLoading(true);
    try {
      await _recurringRepo.deleteRecurring(recurringId);
      _error = '';
    } catch (e) {
      _error = 'Không thể xóa giao dịch định kỳ: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> toggleRecurring(String recurringId, bool active) async {
    _setLoading(true);
    try {
      await _recurringRepo.toggleRecurring(recurringId, active);
      _error = '';
    } catch (e) {
      _error = 'Không thể thay đổi trạng thái giao dịch định kỳ: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> updateNextRun(String recurringId, DateTime nextRun) async {
    _setLoading(true);
    try {
      await _recurringRepo.updateNextRun(recurringId, nextRun);
      _error = '';
    } catch (e) {
      _error = 'Không thể cập nhật lần chạy tiếp theo: $e';
    }
    _setLoading(false);
    notifyListeners();
  }

  List<Recurring> getActiveRecurrings() {
    return _recurrings.where((recurring) => recurring.active).toList();
  }

  List<Recurring> getInactiveRecurrings() {
    return _recurrings.where((recurring) => !recurring.active).toList();
  }

  List<Recurring> getDueRecurrings() {
    return _recurrings.where((recurring) => recurring.isDueToday).toList();
  }

  List<Recurring> getOverdueRecurrings() {
    return _recurrings.where((recurring) => recurring.isOverdue).toList();
  }

  List<Recurring> getUpcomingRecurrings() {
    return _recurrings
        .where((recurring) =>
            recurring.active && !recurring.isDueToday && !recurring.isOverdue)
        .toList();
  }

  List<Recurring> getRecurringsByFrequency(String frequency) {
    return _recurrings
        .where((recurring) => recurring.frequency == frequency)
        .toList();
  }

  List<Recurring> getRecurringsByType(String type) {
    return _recurrings
        .where((recurring) => recurring.templateTx.type == type)
        .toList();
  }

  int getActiveRecurringsCount() {
    return _recurrings.where((recurring) => recurring.active).length;
  }

  int getDueRecurringsCount() {
    return _recurrings.where((recurring) => recurring.isDueToday).length;
  }

  int getOverdueRecurringsCount() {
    return _recurrings.where((recurring) => recurring.isOverdue).length;
  }

  bool hasDueRecurrings() {
    return _recurrings.any((recurring) => recurring.isDueToday);
  }

  bool hasOverdueRecurrings() {
    return _recurrings.any((recurring) => recurring.isOverdue);
  }

  Map<String, int> getFrequencyBreakdown() {
    final Map<String, int> breakdown = {};
    for (var recurring in _recurrings) {
      final frequency = recurring.frequency;
      breakdown[frequency] = (breakdown[frequency] ?? 0) + 1;
    }
    return breakdown;
  }

  Map<String, int> getTypeBreakdown() {
    final Map<String, int> breakdown = {};
    for (var recurring in _recurrings) {
      final type = recurring.templateTx.type;
      breakdown[type] = (breakdown[type] ?? 0) + 1;
    }
    return breakdown;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
