import 'package:uuid/uuid.dart';

class ImportLog {
  ImportLog({
    required this.id,
    required this.fileName,
    required this.importTime,
    required this.totalRows,
    required this.successRows,
    required this.duplicateRows,
    required this.failedRows,
    required this.mappingJson,
    required this.createdAt,
  });

  factory ImportLog.create({
    required String fileName,
    required int totalRows,
    required int successRows,
    required int duplicateRows,
    required int failedRows,
    required String mappingJson,
  }) {
    final now = DateTime.now().toIso8601String();
    return ImportLog(
      id: const Uuid().v4(),
      fileName: fileName,
      importTime: now,
      totalRows: totalRows,
      successRows: successRows,
      duplicateRows: duplicateRows,
      failedRows: failedRows,
      mappingJson: mappingJson,
      createdAt: now,
    );
  }

  final String id;
  final String fileName;
  final String importTime;
  final int totalRows;
  final int successRows;
  final int duplicateRows;
  final int failedRows;
  final String mappingJson;
  final String createdAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'file_name': fileName,
    'import_time': importTime,
    'total_rows': totalRows,
    'success_rows': successRows,
    'duplicate_rows': duplicateRows,
    'failed_rows': failedRows,
    'mapping_json': mappingJson,
    'created_at': createdAt,
  };
}
