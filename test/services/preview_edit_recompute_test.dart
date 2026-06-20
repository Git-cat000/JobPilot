import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_mobile/data/models/application_record.dart';
import 'package:jobpilot_mobile/features/import_export/services/import_parser.dart';
import 'package:jobpilot_mobile/shared/state/app_controller.dart';

void main() {
  test(
    'updatePreviewRecord recomputes duplicate status after edit instead of '
    'resetting to importable',
    () async {
      const csvText = '''
公司,岗位,投递时间
长鑫存储,半导体算法工程师,2026-06-18
''';
      // 既有记录与导入行同公司同岗位同日期 → 解析阶段应判为疑似重复。
      final controller = AppController();
      controller.applications = [
        ApplicationRecord.create(
          companyName: '长鑫存储',
          jobTitle: '半导体算法工程师',
          applyDate: '2026-06-18',
        ),
      ];
      controller.currentPreview = await ImportParser().parseCsvText(
        csvText,
        existing: controller.applications,
      );
      expect(
        controller.currentPreview!.rows.single.status,
        ImportRowStatus.suspectedDuplicate,
      );

      // 编辑成与既有记录不同的公司：重复状态应被重算为可导入，
      // 而不是被一刀切回 importable（旧实现才会这样做）。
      controller.updatePreviewRecord(
        0,
        ApplicationRecord.create(
          companyName: '华为',
          jobTitle: 'AI算法工程师',
          applyDate: '2026-06-18',
        ),
      );
      expect(
        controller.currentPreview!.rows.single.status,
        ImportRowStatus.importable,
      );
      expect(
        controller.currentPreview!.rows.single.record.companyName,
        '华为',
      );

      // 再改回与既有记录完全相同 → 重复状态应重新出现。
      controller.updatePreviewRecord(
        0,
        ApplicationRecord.create(
          companyName: '长鑫存储',
          jobTitle: '半导体算法工程师',
          applyDate: '2026-06-18',
        ),
      );
      expect(
        controller.currentPreview!.rows.single.status,
        ImportRowStatus.suspectedDuplicate,
      );
    },
  );

  test('updatePreviewRecord marks missing required fields after edit', () async {
    const csvText = '''
公司,岗位,投递时间
华为,AI算法工程师,2026-06-18
''';
    final controller = AppController();
    controller.currentPreview = await ImportParser().parseCsvText(
      csvText,
      existing: [],
    );
    controller.updatePreviewRecord(
      0,
      ApplicationRecord.create(companyName: '华为', jobTitle: '', applyDate: ''),
    );
    expect(
      controller.currentPreview!.rows.single.status,
      ImportRowStatus.missingRequired,
    );
  });
}
