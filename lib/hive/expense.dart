import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime dateTime;

  @HiveField(5)
  final String currency;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.dateTime,
    this.currency = 'VND', // TODO(CURSOR): Set default currency
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'description': description,
      'dateTime': dateTime.toUtc(),
      'currency': currency,
    };
  }

  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      dateTime: map['dateTime'] != null
          ? (map['dateTime'] as DateTime).toLocal()
          : DateTime.now(),
      currency: map['currency'] ?? 'VND',
    );
  }
}
