import 'package:cloud_firestore/cloud_firestore.dart';

class Account {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'card', 'ewallet'
  final String currency;
  final double balance;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'currency': currency,
      'balance': balance,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Account.fromMap(String id, Map<String, dynamic> map) {
    return Account(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? 'cash',
      currency: map['currency'] ?? 'USD',
      balance: (map['balance'] ?? 0.0).toDouble(),
      isDefault: map['isDefault'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Account copyWith({
    String? name,
    String? type,
    String? currency,
    double? balance,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case 'cash':
        return 'Tiền mặt';
      case 'bank':
        return 'Ngân hàng';
      case 'card':
        return 'Thẻ';
      case 'ewallet':
        return 'Ví điện tử';
      default:
        return 'Khác';
    }
  }

  String get typeIcon {
    switch (type) {
      case 'cash':
        return '💵';
      case 'bank':
        return '🏦';
      case 'card':
        return '💳';
      case 'ewallet':
        return '📱';
      default:
        return '💰';
    }
  }
}
