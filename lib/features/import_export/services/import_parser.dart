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
    'job_title': ['岗位', '岗位名称', '职位', '职位名称', '申请岗位', 'Job Title'],
    'job_direction': ['方向', '岗位方向', '职位方向', '求职方向'],
    'status': ['状态', '流程', '进度', '当前状态', '求职状态', '面试状态', '投递状态'],
    'apply_date': ['日期', '投递日期', '投递时间', '申请时间', '申请日期', '提交时间'],
    'next_follow_date': ['下次跟进', '下次跟进日期', '跟进日期', '跟进时间'],
    'city': ['城市', '地点', '工作地点', '工作城市', 'base', 'Base'],
    'channel': ['渠道', '投递渠道', '来源', '平台', '投递平台'],
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
    // 依次检查每个 sheet，选第一个含有可识别表头且至少一行数据的 sheet，
    // 而不是盲目取第一个 sheet（它可能为空或仅作说明）。
    for (final sheetName in workbook.tables.keys) {
      final sheet = workbook.tables[sheetName]!;
      final rows = sheet.rows.map((row) => row.map(_cellText).toList()).toList();
      final headerIndex = _detectHeaderRow(rows);
      if (headerIndex == null) {
        continue;
      }
      // 跳过只有表头没有数据行的 sheet。
      final dataRows = rows.skip(headerIndex + 1).where(
        (row) => row.any((cell) => cell.toString().trim().isNotEmpty),
      );
      if (dataRows.isEmpty) {
        continue;
      }
      return _parseTable(fileName, rows, existing);
    }
    return ImportPreview(fileName: fileName, mapping: const {}, rows: const []);
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

    // 统一转成字符串行，CSV 与 XLSX 走同一条「检测表头 → 解析数据」路径。
    final rows = table
        .map((row) => row.map((cell) => cell.toString()).toList())
        .toList();
    final headerIndex = _detectHeaderRow(rows);
    if (headerIndex == null) {
      return ImportPreview(fileName: fileName, mapping: const {}, rows: const []);
    }
    final headers = rows[headerIndex];
    final mapping = _buildMapping(headers);
    final previewRows = <ImportPreviewRow>[];
    // 同一批次内已构建的可导入记录，用于检测文件内部自身重复：
    // 仅对比数据库既有记录会让同一文件里的两行相同数据都被判为可导入并重复入库。
    final batchSeen = <ApplicationRecord>[];

    for (final row in rows.skip(headerIndex + 1)) {
      if (row.every((cell) => cell.trim().isEmpty)) {
        continue;
      }
      // 跳过重复表头行：整行单元格再次命中表头别名（含公司+岗位）。
      if (_isHeaderCandidate(row)) {
        continue;
      }
      final values = <String, String>{};
      for (var index = 0; index < headers.length; index++) {
        final key = mapping[headers[index]];
        if (key == null || index >= row.length) {
          continue;
        }
        values[key] = row[index].trim();
      }

      final statusText = values['status'] ?? '';
      final explicitDirection = _directionFromImportedValue(
        values['job_direction'] ?? '',
      );
      final directionText = [
        values['job_title'] ?? '',
        values['remark'] ?? '',
        values['jd_link'] ?? '',
        values['channel'] ?? '',
      ].join(' ');
      final record = ApplicationRecord.create(
        companyName: values['company_name'] ?? '',
        jobTitle: values['job_title'] ?? '',
        jobDirection:
            explicitDirection ?? classifier.detectDirection(directionText),
        city: values['city'] ?? '',
        channel: values['channel'] ?? '',
        status: classifier.detectStatus(statusText),
        priority: values['priority'] ?? 'B',
        applyDate: values['apply_date'] ?? '',
        nextFollowDate: values['next_follow_date'] ?? '',
        jdLink: values['jd_link'] ?? '',
        resumeVersion: values['resume_version'] ?? '',
        salaryRange: values['salary_range'] ?? '',
        remark: values['remark'] ?? '',
      );

      // 重复检测同时覆盖数据库既有记录与本批次已见记录。
      final rowStatus = statusFor(record, [...existing, ...batchSeen]);
      if (record.hasRequiredFields) {
        batchSeen.add(record);
      }
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

  /// 在前若干行中搜索最佳表头行：要求同时覆盖 company_name 与 job_title，
  /// 返回第一个满足条件的行号；找不到返回 null。
  int? _detectHeaderRow(List<List<String>> rows) {
    final limit = rows.length < 20 ? rows.length : 20;
    for (var i = 0; i < limit; i++) {
      final keys = _mappedKeys(rows[i]);
      if (keys.contains('company_name') && keys.contains('job_title')) {
        return i;
      }
    }
    return null;
  }

  /// 某行是否本身就是一个表头候选（用于跳过重复表头行）。
  bool _isHeaderCandidate(List<dynamic> row) {
    final keys = _mappedKeys(row.map((cell) => cell.toString()).toList());
    return keys.contains('company_name') && keys.contains('job_title');
  }

  /// 计算一行单元格能命中的别名 key 集合（按规范化后整串匹配）。
  Set<String> _mappedKeys(List<String> cells) {
    final keys = <String>{};
    for (final cell in cells) {
      final normalized = _normalizeHeader(cell);
      if (normalized.isEmpty) {
        continue;
      }
      for (final entry in aliases.entries) {
        if (entry.value.map(_normalizeHeader).contains(normalized)) {
          keys.add(entry.key);
          break;
        }
      }
    }
    return keys;
  }

  Map<String, String> _buildMapping(List<String> headers) {
    final mapping = <String, String>{};
    for (final header in headers) {
      final normalizedHeader = _normalizeHeader(header);
      for (final entry in aliases.entries) {
        final candidates = entry.value.map(_normalizeHeader);
        if (candidates.contains(normalizedHeader)) {
          mapping[header] = entry.key;
          break;
        }
      }
    }
    return mapping;
  }

  String _normalizeHeader(String value) {
    return value
        .replaceAll('\ufeff', '')
        .replaceAll(RegExp(r'（.*?）|\(.*?\)'), '')
        .replaceAll(RegExp(r'[\s:：_\-—/\\|]+'), '')
        .trim()
        .toLowerCase();
  }

  String? _directionFromImportedValue(String value) {
    final normalized = _normalizeHeader(value);
    const labels = {
      'semiconductor': ['semiconductor', '半导体'],
      'ai_algorithm': ['aialgorithm', 'ai算法', '算法', '人工智能'],
      'quant': ['quant', '量化'],
      'internet_dev': ['internetdev', '互联网开发', '开发', '软件开发', '客户端开发'],
      'embedded': ['embedded', '嵌入式', '固件'],
      'data_analysis': ['dataanalysis', '数据分析', 'bi'],
      'product': ['product', '产品', '产品经理'],
      'operations': ['operations', '运营'],
      'finance': ['finance', '金融', '投研'],
      'consulting': ['consulting', '咨询'],
      'research': ['research', '科研', '研究'],
      'other': ['other', '其他'],
    };
    for (final entry in labels.entries) {
      if (entry.value.map(_normalizeHeader).contains(normalized)) {
        return entry.key;
      }
    }
    return null;
  }

  String _cellText(Data? cell) {
    final value = cell?.value;
    if (value == null) {
      return '';
    }
    if (value is TextCellValue) {
      // TextSpan 可能带 children（富文本），用 toString 合并全部文本。
      return value.value.toString();
    }
    if (value is DateCellValue) {
      return value.asDateTimeLocal().toIso8601String().split('T').first;
    }
    if (value is DateTimeCellValue) {
      return value.asDateTimeLocal().toIso8601String().split('T').first;
    }
    if (value is TimeCellValue) {
      return value.toString();
    }
    if (value is IntCellValue) {
      return value.value.toString();
    }
    if (value is DoubleCellValue) {
      return _doubleToString(value.value);
    }
    if (value is BoolCellValue) {
      return value.value ? 'true' : 'false';
    }
    if (value is FormulaCellValue) {
      return value.formula;
    }
    return value.toString();
  }

  String _doubleToString(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toString();
  }

  /// 依据必填字段与重复检测推导一行预览的导入状态。
  /// 解析与编辑预览行共用此逻辑，确保用户改动公司/岗位/投递日期后
  /// 重复状态会被重新计算（而不是一律回到 importable）。
  ImportRowStatus statusFor(
    ApplicationRecord record,
    List<ApplicationRecord> existing,
  ) {
    if (!record.hasRequiredFields) {
      return ImportRowStatus.missingRequired;
    }
    return _duplicateStatus(record, existing) ?? ImportRowStatus.importable;
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
