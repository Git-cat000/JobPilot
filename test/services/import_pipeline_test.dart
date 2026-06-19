import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_mobile/data/models/application_record.dart';
import 'package:jobpilot_mobile/features/import_export/services/import_parser.dart';

void main() {
  test('maps aliases and classifies imported csv rows', () async {
    const csvText = '''
公司,岗位,城市,投递状态,投递时间,渠道,备注
长鑫存储,半导体算法工程师,合肥,已投,2026-06-18,官网,突出CST和Python数据分析
华为,AI算法工程师,深圳,一面,2026-06-15,内推,准备项目介绍
''';

    final preview = await ImportParser().parseCsvText(csvText, existing: []);

    expect(preview.totalRows, 2);
    expect(preview.importableRows, 2);
    expect(preview.mapping['公司'], 'company_name');
    expect(preview.rows.first.record.companyName, '长鑫存储');
    expect(preview.rows.first.record.status, 'applied');
    expect(preview.rows.first.record.jobDirection, 'semiconductor');
    expect(preview.rows[1].record.status, 'first_interview');
    expect(preview.rows[1].record.jobDirection, 'ai_algorithm');
  });

  test(
    'marks missing required fields and duplicate rows before import',
    () async {
      const csvText = '''
公司,岗位,投递时间
长鑫存储,半导体算法工程师,2026-06-18
空岗位公司,,2026-06-18
''';
      final existing = [
        ApplicationRecord.create(
          companyName: '长鑫存储',
          jobTitle: '半导体算法工程师',
          applyDate: '2026-06-18',
        ),
      ];

      final preview = await ImportParser().parseCsvText(
        csvText,
        existing: existing,
      );

      expect(preview.duplicateRows, 1);
      expect(preview.failedRows, 1);
      expect(preview.rows.first.status, ImportRowStatus.suspectedDuplicate);
      expect(preview.rows[1].status, ImportRowStatus.missingRequired);
    },
  );

  test(
    'normalizes decorated headers and uses explicit direction columns',
    () async {
      const csvText = '''
 公司名称 ,岗位名称（必填）,工作城市,当前状态,申请日期,投递平台,岗位方向
荣耀,客户端开发工程师,深圳,HR面,2026-06-18,官网,互联网开发
''';

      final preview = await ImportParser().parseCsvText(csvText, existing: []);

      expect(preview.mapping.values, contains('company_name'));
      expect(preview.mapping.values, contains('job_title'));
      expect(preview.mapping.values, contains('status'));
      expect(preview.mapping.values, contains('channel'));
      expect(preview.rows.single.record.companyName, '荣耀');
      expect(preview.rows.single.record.jobTitle, '客户端开发工程师');
      expect(preview.rows.single.record.city, '深圳');
      expect(preview.rows.single.record.status, 'hr_interview');
      expect(preview.rows.single.record.jobDirection, 'internet_dev');
    },
  );

  test('robust xlsx parsing with mixed sheets and typed cells', () async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet()!;
    excel.rename(defaultSheet, '空表'); // 第一个 sheet 留空

    final data = excel['数据']; // 第二个 sheet 才有真实数据
    // 前置说明行（无映射数据）。
    data.appendRow([TextCellValue('请按下列格式填写，不要修改表头')]);
    // 装饰性双语表头。
    data.appendRow([
      TextCellValue('公司名称 (Company)'),
      TextCellValue('岗位名称（必填）'),
      TextCellValue('工作城市'),
      TextCellValue('当前状态'),
      TextCellValue('申请日期'),
      TextCellValue('投递平台'),
      TextCellValue('薪资'),
      TextCellValue('备注'),
      TextCellValue('应届'), // 未映射列，放布尔值验证不崩溃。
    ]);
    // 真实数据行：含日期 / 整数 / 布尔类型单元格。
    data.appendRow([
      TextCellValue('长鑫存储'),
      TextCellValue('半导体算法工程师'),
      TextCellValue('合肥'),
      TextCellValue('已投'),
      const DateCellValue(year: 2026, month: 6, day: 18),
      TextCellValue('官网'),
      const IntCellValue(25),
      TextCellValue('CST'),
      const BoolCellValue(true),
    ]);
    // 重复表头行，应被跳过。
    data.appendRow([
      TextCellValue('公司名称 (Company)'),
      TextCellValue('岗位名称（必填）'),
      TextCellValue('工作城市'),
      TextCellValue('当前状态'),
      TextCellValue('申请日期'),
      TextCellValue('投递平台'),
      TextCellValue('薪资'),
      TextCellValue('备注'),
      TextCellValue('应届'),
    ]);
    // 尾部空行，应被跳过。
    data.appendRow(List<CellValue?>.filled(9, null));
    // 第二条真实数据行。
    data.appendRow([
      TextCellValue('华为'),
      TextCellValue('AI算法工程师'),
      TextCellValue('深圳'),
      TextCellValue('流程终止'),
      const DateCellValue(year: 2026, month: 6, day: 15),
      TextCellValue('内推'),
      const IntCellValue(30),
      TextCellValue('准备项目介绍'),
      const BoolCellValue(false),
    ]);

    final bytes = Uint8List.fromList(excel.encode()!);
    final preview = await ImportParser().parseXlsxBytes(
      bytes,
      fileName: 'mixed.xlsx',
      existing: [],
    );

    expect(preview.totalRows, 2);
    expect(preview.mapping.values, contains('company_name'));
    expect(preview.mapping.values, contains('job_title'));
    expect(preview.mapping.values, contains('status'));
    expect(preview.mapping.values, contains('channel'));
    expect(preview.mapping.values, contains('salary_range'));

    final first = preview.rows[0].record;
    expect(first.companyName, '长鑫存储');
    expect(first.status, 'applied');
    expect(first.applyDate, '2026-06-18');
    expect(first.salaryRange, '25');

    final second = preview.rows[1].record;
    expect(second.companyName, '华为');
    expect(second.status, 'process_terminated');
    expect(second.applyDate, '2026-06-15');
    expect(second.salaryRange, '30');
  });
}
