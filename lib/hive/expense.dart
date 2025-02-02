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

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.dateTime,
  });
}
