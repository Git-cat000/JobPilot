import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../../../data/models/application_record.dart';
import '../../classification/classification_service.dart';

enum ImportRowStatus {
  importable('可导入'),
  missingRequired('缺少必填字段'),
  suspectedDuplicate('疑似重复'),
  possibleDuplicate('可能重复'),
  invalidField('字段异常');

  const ImportRowStatus(this.label);
  final String label;
}

class ImportPreview {
  const ImportPreview({
    required this.fileName,
    required this.mapping,
    required this.rows,
  });

  final String fileName;
  final Map<String, String> mapping;
  final List<ImportPreviewRow> rows;

  int get totalRows => rows.length;
  int get importableRows => rows.where((row) => row.canImport).length;
  int get failedRows =>
      rows.where((row) => row.status == ImportRowStatus.missingRequired).length;
  int get duplicateRows => rows
      .where((row) => row.status == ImportRowStatus.suspectedDuplicate)
      .length;
}

class ImportPreviewRow {
  const ImportPreviewRow({
    required this.record,
    required this.status,
    required this.message,
  });

  final ApplicationRecord record;
  final ImportRowStatus status;
  final String message;

  bool get canImport => status != ImportRowStatus.missingRequired;
}

class ImportParser {
  ImportParser({ClassificationService? classifier})
    : classifier = classifier ?? ClassificationService();

  final ClassificationService classifier;

  static const aliases = {
    'company_name': ['公司', '公司名称', '企业', '单位', '投递公司', '目标公司'],
    'job_title': ['岗位', '职位', '职位名称', '申请岗位', 'Job Title'],
    'status': ['状态', '流程', '进度', '求职状态', '面试状态', '投递状态'],
    'apply_date': ['日期', '投递日期', '投递时间', '申请时间', '提交时间'],
    'city': ['城市', '地点', '工作地点', 'base', 'Base'],
    'channel': ['渠道', '投递渠道', '来源', '平台'],
    'jd_link': ['链接', '岗位链接', '招聘链接', 'URL', 'url'],
    'remark': ['备注', '说明', '记录', '补充信息'],
    'priority': ['优先级', '重要程度'],
    'resume_version': ['简历版本', '使用简历', '投递简历'],
    'salary_range': ['薪资', '薪资范围', '待遇'],
  };

  Future<ImportPreview> parseCsvBytes(
    Uint8List bytes, {
    required String fileName,
    required List<ApplicationRecord> existing,
  }) {
    final text = utf8.decode(bytes, allowMalformed: true);
    return parseCsvText(text, fileName: fileName, existing: existing);
  }

  Future<ImportPreview> parseCsvText(
    String text, {
    String fileName = 'manual.csv',
    required List<ApplicationRecord> existing,
  }) async {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(normalized)
        .where((row) {
          return row.any((cell) => cell.toString().trim().isNotEmpty);
        })
        .toList();
    return _parseTable(fileName, rows, existing);
  }

  Future<ImportPreview> parseXlsxBytes(
    Uint8List bytes, {
    required String fileName,
    required List<ApplicationRecord> existing,
  }) async {
    final workbook = Excel.decodeBytes(bytes);
    final firstSheetName = workbook.tables.keys.first;
    final sheet = workbook.tables[firstSheetName]!;
    final rows = sheet.rows
        .map((row) => row.map((cell) => cell?.value?.toString() ?? '').toList())
        .toList();
    return _parseTable(fileName, rows, existing);
  }

  ImportPreview _parseTable(
    String fileName,
    List<List<dynamic>> table,
    List<ApplicationRecord> existing,
  ) {
    if (table.isEmpty) {
      return ImportPreview(
        fileName: fileName,
        mapping: const {},
        rows: const [],
      );
    }

    final headers = table.first.map((cell) => cell.toString().trim()).toList();
    final mapping = _buildMapping(headers);
    final previewRows = <ImportPreviewRow>[];

    for (final row in table.skip(1)) {
      if (row.every((cell) => cell.toString().trim().isEmpty)) {
        continue;
      }
      final values = <String, String>{};
      for (var index = 0; index < headers.length; index++) {
        final key = mapping[headers[index]];
        if (key == null || index >= row.length) {
          continue;
        }
        values[key] = row[index].toString().trim();
      }

      final statusText = values['status'] ?? '';
      final directionText = [
        values['job_title'] ?? '',
        values['remark'] ?? '',
        values['jd_link'] ?? '',
        values['channel'] ?? '',
      ].join(' ');
      final record = ApplicationRecord.create(
        companyName: values['company_name'] ?? '',
        jobTitle: values['job_title'] ?? '',
        jobDirection: classifier.detectDirection(directionText),
        city: values['city'] ?? '',
        channel: values['channel'] ?? '',
        status: classifier.detectStatus(statusText),
        priority: values['priority'] ?? 'B',
        applyDate: values['apply_date'] ?? '',
        jdLink: values['jd_link'] ?? '',
        resumeVersion: values['resume_version'] ?? '',
        salaryRange: values['salary_range'] ?? '',
        remark: values['remark'] ?? '',
      );

      final duplicateStatus = _duplicateStatus(record, existing);
      final rowStatus = record.hasRequiredFields
          ? duplicateStatus ?? ImportRowStatus.importable
          : ImportRowStatus.missingRequired;
      previewRows.add(
        ImportPreviewRow(
          record: record,
          status: rowStatus,
          message: rowStatus.label,
        ),
      );
    }

    return ImportPreview(
      fileName: fileName,
      mapping: mapping,
      rows: previewRows,
    );
  }

  Map<String, String> _buildMapping(List<String> headers) {
    final mapping = <String, String>{};
    for (final header in headers) {
      for (final entry in aliases.entries) {
        final candidates = entry.value.map((alias) => alias.toLowerCase());
        if (candidates.contains(header.toLowerCase())) {
          mapping[header] = entry.key;
          break;
        }
      }
    }
    return mapping;
  }

  ImportRowStatus? _duplicateStatus(
    ApplicationRecord record,
    List<ApplicationRecord> existing,
  ) {
    for (final item in existing) {
      final sameCompany = item.companyName == record.companyName;
      final sameTitle = item.jobTitle == record.jobTitle;
      if (!sameCompany || !sameTitle) {
        continue;
      }
      if (item.applyDate == record.applyDate) {
        return ImportRowStatus.suspectedDuplicate;
      }
      return ImportRowStatus.possibleDuplicate;
    }
    return null;
  }
}
