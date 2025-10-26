import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String id;
  final String type; // 'expense', 'income', 'transfer', 'refund'
  final String accountId;
  final String? toAccountId; // For transfers
  final String? categoryId;
  final double amount;
  final String currency;
  final String description;
  final String? merchantId;
  final List<String> tags;
  final DateTime dateTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  final String? attachmentUrl;
  final bool isAdjustment;

  const Transaction({
    required this.id,
    required this.type,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    required this.amount,
    required this.currency,
    required this.description,
    this.merchantId,
    required this.tags,
    required this.dateTime,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    this.attachmentUrl,
    this.isAdjustment = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'categoryId': categoryId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'merchantId': merchantId,
      'tags': tags,
      'dateTime': Timestamp.fromDate(dateTime.toUtc()),
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
      'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
      'deleted': deleted,
      'attachmentUrl': attachmentUrl,
      'isAdjustment': isAdjustment,
    };
  }

  factory Transaction.fromMap(String id, Map<String, dynamic> data) {
    return Transaction(
      id: id,
      type: (data['type'] as String?) ?? 'expense',
      accountId: (data['accountId'] as String?) ?? '',
      toAccountId: data['toAccountId'] as String?,
      categoryId: data['categoryId'] as String?,
      amount:
          (data['amount'] is num) ? (data['amount'] as num).toDouble() : 0.0,
      currency: (data['currency'] as String?) ?? 'USD',
      description: (data['description'] as String?) ?? '',
      merchantId: data['merchantId'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
      dateTime: () {
        final raw = data['dateTime'];
        if (raw is Timestamp) {
          final date = raw.toDate().toLocal();
          return date;
        }
        if (raw is String) {
          final date = DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
          return date;
        }
        return DateTime.now();
      }(),
      createdAt: () {
        final raw = data['createdAt'];
        if (raw is Timestamp) return raw.toDate().toLocal();
        if (raw is String)
          return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
        return DateTime.now();
      }(),
      updatedAt: () {
        final raw = data['updatedAt'];
        if (raw is Timestamp) return raw.toDate().toLocal();
        if (raw is String)
          return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
        return DateTime.now();
      }(),
      deleted: (data['deleted'] as bool?) ?? false,
      attachmentUrl: data['attachmentUrl'] as String?,
      isAdjustment: (data['isAdjustment'] as bool?) ?? false,
    );
  }

  Transaction copyWith({
    String? type,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    double? amount,
    String? currency,
    String? description,
    String? merchantId,
    List<String>? tags,
    DateTime? dateTime,
    DateTime? updatedAt,
    bool? deleted,
    String? attachmentUrl,
    bool? isAdjustment,
  }) {
    return Transaction(
      id: id,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      merchantId: merchantId ?? this.merchantId,
      tags: tags ?? this.tags,
      dateTime: dateTime ?? this.dateTime,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      isAdjustment: isAdjustment ?? this.isAdjustment,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case 'expense':
        return 'Chi tiêu';
      case 'income':
        return 'Thu nhập';
      case 'transfer':
        return 'Chuyển khoản';
      case 'refund':
        return 'Hoàn tiền';
      default:
        return 'Khác';
    }
  }

  String get typeIcon {
    switch (type) {
      case 'expense':
        return '💸';
      case 'income':
        return '💰';
      case 'transfer':
        return '🔄';
      case 'refund':
        return '↩️';
      default:
        return '📝';
    }
  }

  bool get isTransfer => type == 'transfer';
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isRefund => type == 'refund';
}
