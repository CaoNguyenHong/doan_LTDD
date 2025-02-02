// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learned_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LearnedCategoryAdapter extends TypeAdapter<LearnedCategory> {
  @override
  final int typeId = 1;

  @override
  LearnedCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LearnedCategory(
      word: fields[0] as String,
      category: fields[1] as String,
      frequency: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LearnedCategory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.word)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.frequency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearnedCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
