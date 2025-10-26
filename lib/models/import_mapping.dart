import 'package:cloud_firestore/cloud_firestore.dart';

class ImportMapping {
  final String id;
  final String sourceName; // e.g., "VCB CSV"
  final Map<String, String>
      columnMap; // {date: "A", description: "B", debit: "C", credit: "D", amount: "E"}
  final String delimiter;
  final String datePattern;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ImportMapping({
    required this.id,
    required this.sourceName,
    required this.columnMap,
    required this.delimiter,
    required this.datePattern,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'sourceName': sourceName,
      'columnMap': columnMap,
      'delimiter': delimiter,
      'datePattern': datePattern,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ImportMapping.fromMap(String id, Map<String, dynamic> map) {
    return ImportMapping(
      id: id,
      sourceName: map['sourceName'] ?? '',
      columnMap: Map<String, String>.from(map['columnMap'] ?? {}),
      delimiter: map['delimiter'] ?? ',',
      datePattern: map['datePattern'] ?? 'yyyy-MM-dd',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  ImportMapping copyWith({
    String? sourceName,
    Map<String, String>? columnMap,
    String? delimiter,
    String? datePattern,
    DateTime? updatedAt,
  }) {
    return ImportMapping(
      id: id,
      sourceName: sourceName ?? this.sourceName,
      columnMap: columnMap ?? this.columnMap,
      delimiter: delimiter ?? this.delimiter,
      datePattern: datePattern ?? this.datePattern,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName => sourceName;

  bool get isValid =>
      sourceName.isNotEmpty &&
      columnMap.isNotEmpty &&
      delimiter.isNotEmpty &&
      datePattern.isNotEmpty;
}
