import 'package:uuid/uuid.dart';

class MaterialItem {
  MaterialItem({
    required this.id,
    required this.name,
    required this.type,
    required this.direction,
    required this.version,
    required this.filePath,
    required this.remark,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaterialItem.create({
    required String name,
    String type = '',
    String direction = 'other',
    String version = '',
    String filePath = '',
    String remark = '',
  }) {
    final now = DateTime.now().toIso8601String();
    return MaterialItem(
      id: const Uuid().v4(),
      name: name,
      type: type,
      direction: direction,
      version: version,
      filePath: filePath,
      remark: remark,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String name;
  final String type;
  final String direction;
  final String version;
  final String filePath;
  final String remark;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'direction': direction,
    'version': version,
    'file_path': filePath,
    'remark': remark,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
