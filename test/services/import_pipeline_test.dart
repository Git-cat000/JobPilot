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
}
