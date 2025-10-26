import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction.dart' as models;

class Recurring {
  final String id;
  final String rule; // RRULE format: "FREQ=MONTHLY;BYMONTHDAY=1"
  final DateTime nextRun;
  final models.Transaction templateTx;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Recurring({
    required this.id,
    required this.rule,
    required this.nextRun,
    required this.templateTx,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'rule': rule,
      'nextRun': Timestamp.fromDate(nextRun),
      'templateTx': templateTx.toMap(),
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Recurring.fromMap(String id, Map<String, dynamic> map) {
    return Recurring(
      id: id,
      rule: map['rule'] ?? '',
      nextRun: (map['nextRun'] as Timestamp).toDate(),
      templateTx: models.Transaction.fromMap('template', map['templateTx']),
      active: map['active'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Recurring copyWith({
    String? rule,
    DateTime? nextRun,
    models.Transaction? templateTx,
    bool? active,
    DateTime? updatedAt,
  }) {
    return Recurring(
      id: id,
      rule: rule ?? this.rule,
      nextRun: nextRun ?? this.nextRun,
      templateTx: templateTx ?? this.templateTx,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get frequency {
    if (rule.contains('FREQ=DAILY')) return 'daily';
    if (rule.contains('FREQ=WEEKLY')) return 'weekly';
    if (rule.contains('FREQ=MONTHLY')) return 'monthly';
    return 'unknown';
  }

  String get frequencyDisplayName {
    switch (frequency) {
      case 'daily':
        return 'Hàng ngày';
      case 'weekly':
        return 'Hàng tuần';
      case 'monthly':
        return 'Hàng tháng';
      default:
        return 'Khác';
    }
  }

  bool get isDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextRunDate = DateTime(nextRun.year, nextRun.month, nextRun.day);
    return today.isAtSameMomentAs(nextRunDate);
  }

  bool get isOverdue {
    return nextRun.isBefore(DateTime.now());
  }

  String get statusText {
    if (isOverdue) return 'Quá hạn';
    if (isDueToday) return 'Hôm nay';
    return 'Sắp tới';
  }

  String get statusColor {
    if (isOverdue) return 'red';
    if (isDueToday) return 'orange';
    return 'green';
  }
}
