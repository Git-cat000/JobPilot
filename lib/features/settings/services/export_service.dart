import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/enums/job_enums.dart';
import '../../../data/db/app_database.dart';
import '../../../data/models/application_record.dart';

class ExportService {
  static const headers = [
    '公司名称',
    '岗位名称',
    '岗位方向',
    '城市',
    '投递渠道',
    '当前状态',
    '优先级',
    '投递日期',
    '下次跟进日期',
    'JD链接',
    '简历版本',
    '薪资范围',
    '备注',
    '创建时间',
    '更新时间',
  ];

  static String buildCsv(List<ApplicationRecord> records) {
    final rows = [
      headers,
      ...records.map(
        (record) => [
          record.companyName,
          record.jobTitle,
          directionLabel(record.jobDirection),
          record.city,
          record.channel,
          statusLabel(record.status),
          priorityLabel(record.priority),
          record.applyDate,
          record.nextFollowDate,
          record.jdLink,
          record.resumeVersion,
          record.salaryRange,
          record.remark,
          record.createdAt,
          record.updatedAt,
        ],
      ),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  Future<File> exportCsv(List<ApplicationRecord> records) async {
    final file = File(p.join(await _exportDirPath(), _timestamped('csv')));
    return file.writeAsString(buildCsv(records), encoding: utf8);
  }

  Future<File> exportXlsx(List<ApplicationRecord> records) async {
    final excel = Excel.createExcel();
    final sheet = excel['Applications'];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (final record in records) {
      sheet.appendRow(
        [
          record.companyName,
          record.jobTitle,
          directionLabel(record.jobDirection),
          record.city,
          record.channel,
          statusLabel(record.status),
          priorityLabel(record.priority),
          record.applyDate,
          record.nextFollowDate,
          record.jdLink,
          record.resumeVersion,
          record.salaryRange,
          record.remark,
          record.createdAt,
          record.updatedAt,
        ].map(TextCellValue.new).toList(),
      );
    }
    final bytes = excel.save() ?? <int>[];
    final file = File(p.join(await _exportDirPath(), _timestamped('xlsx')));
    return file.writeAsBytes(bytes);
  }

  Future<File> exportJobpack({
    required String databasePath,
    required int applicationCount,
    required int stageCount,
    required String appVersion,
  }) async {
    final exportDir = Directory(await _exportDirPath());
    final file = File(p.join(exportDir.path, _timestamped('jobpack')));
    final encoder = ZipFileEncoder()..create(file.path);
    encoder.addFile(File(databasePath), 'data.sqlite');
    final now = DateTime.now().toIso8601String();
    encoder.addArchiveFile(
      ArchiveFile.string(
        'metadata.json',
        jsonEncode({
          'app_name': 'JobPilot',
          'export_time': now,
          'application_count': applicationCount,
          'stage_count': stageCount,
          'version': appVersion,
        }),
      ),
    );
    encoder.addArchiveFile(
      ArchiveFile.string(
        'version.json',
        jsonEncode({
          'schema_version': AppDatabase.schemaVersion,
          'app_version': appVersion,
        }),
      ),
    );
    encoder.close();
    return file;
  }

  Future<String> _exportDirPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }
    return exportDir.path;
  }

  String _timestamped(String extension) {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'jobpilot_export_$stamp.$extension';
  }
}
