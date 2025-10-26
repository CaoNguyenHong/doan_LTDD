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
      'dateTime': Timestamp.fromDate(dateTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deleted': deleted,
      'attachmentUrl': attachmentUrl,
      'isAdjustment': isAdjustment,
    };
  }

  factory Transaction.fromMap(String id, Map<String, dynamic> map) {
    return Transaction(
      id: id,
      type: map['type'] ?? 'expense',
      accountId: map['accountId'] ?? '',
      toAccountId: map['toAccountId'],
      categoryId: map['categoryId'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      description: map['description'] ?? '',
      merchantId: map['merchantId'],
      tags: List<String>.from(map['tags'] ?? []),
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      deleted: map['deleted'] ?? false,
      attachmentUrl: map['attachmentUrl'],
      isAdjustment: map['isAdjustment'] ?? false,
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
