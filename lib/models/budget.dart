import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String period; // 'monthly', 'weekly'
  final String month; // 'YYYY-MM' format
  final String? categoryId; // null for global budget
  final double limit;
  final double spent;
  final DateTime updatedAt;

  const Budget({
    required this.id,
    required this.period,
    required this.month,
    this.categoryId,
    required this.limit,
    required this.spent,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'period': period,
      'month': month,
      'categoryId': categoryId,
      'limit': limit,
      'spent': spent,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Budget.fromMap(String id, Map<String, dynamic> map) {
    return Budget(
      id: id,
      period: map['period'] ?? 'monthly',
      month: map['month'] ?? '',
      categoryId: map['categoryId'],
      limit: (map['limit'] ?? 0.0).toDouble(),
      spent: (map['spent'] ?? 0.0).toDouble(),
      updatedAt: map['updatedAt'] != null && map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Budget copyWith({
    String? period,
    String? month,
    String? categoryId,
    double? limit,
    double? spent,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id,
      period: period ?? this.period,
      month: month ?? this.month,
      categoryId: categoryId, // Allow null values to be set
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get remaining => limit - spent;
  double get percentage => limit > 0 ? (spent / limit) * 100 : 0;

  bool get isOverBudget => spent > limit;
  bool get isNearLimit => percentage >= 80 && percentage < 100;
  bool get isWarning => percentage >= 100;

  String get periodDisplayName {
    switch (period) {
      case 'daily':
        return 'Hàng ngày';
      case 'weekly':
        return 'Hàng tuần';
      case 'monthly':
        return 'Hàng tháng';
      case 'yearly':
        return 'Hàng năm';
      default:
        return 'Khác';
    }
  }

  String get statusColor {
    if (isWarning) return 'red';
    if (isNearLimit) return 'orange';
    return 'green';
  }

  String get statusText {
    if (isWarning) return 'Vượt quá ngân sách';
    if (isNearLimit) return 'Gần đạt giới hạn';
    return 'Trong ngân sách';
  }
}
