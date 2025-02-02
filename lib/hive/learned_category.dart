import 'package:hive/hive.dart';

part 'learned_category.g.dart';

@HiveType(typeId: 1)
class LearnedCategory extends HiveObject {
  @HiveField(0)
  final String word;

  @HiveField(1)
  final String category;

  @HiveField(2)
  int frequency;

  LearnedCategory({
    required this.word,
    required this.category,
    this.frequency = 1,
  });
}
