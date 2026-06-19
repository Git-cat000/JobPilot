import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_mobile/core/app_strings.dart';

void main() {
  group('AppStrings English coverage', () {
    final en = AppStrings('en');

    test('navigation and common', () {
      expect(en.home, 'Home');
      expect(en.applications, 'Jobs');
      expect(en.import, 'Import');
      expect(en.statistics, 'Stats');
      expect(en.settings, 'Settings');
      expect(en.add, 'Add');
      expect(en.edit, 'Edit');
      expect(en.delete, 'Delete');
      expect(en.cancel, 'Cancel');
      expect(en.save, 'Save');
      expect(en.confirm, 'Confirm');
      expect(en.select, 'Select');
      expect(en.done, 'Done');
      expect(en.close, 'Close');
    });

    test('dashboard', () {
      expect(en.appTitle, 'JobPilot');
      expect(en.totalApplications, 'Total');
      expect(en.active, 'Active');
      expect(en.interviewing, 'Interviewing');
      expect(en.offerCount, 'Offers');
      expect(en.followUp, 'Follow-up');
      expect(en.recentApplications, 'Recent applications');
    });

    test('applications list', () {
      expect(en.jobRecords, 'Applications');
      expect(en.noMatch, contains('No matching'));
      expect(en.selectAll, 'Select all');
      expect(en.deselectAll, 'Deselect all');
      expect(en.bulkDeleteTitle, 'Delete selected?');
      expect(en.selectedCount(3), '3 selected');
      expect(en.bulkDeleteContent(2), contains('2 application'));
    });

    test('detail page', () {
      expect(en.detailTitle, 'Application detail');
      expect(en.notFound, contains('not found'));
      expect(en.cityMissing, 'City not set');
      expect(en.stageRecords, 'Stage records');
      expect(en.addStage, 'Add stage');
      expect(en.remarkTitle, 'Remark');
      expect(en.deleteTitle, 'Delete application?');
    });

    test('import and preview', () {
      expect(en.import, 'Import');
      expect(en.chooseFileTitle, contains('CSV'));
      expect(en.importPreview, 'Import preview');
      expect(en.totalRows, 'Total');
      expect(en.importable, 'Importable');
      expect(en.errors, 'Errors');
      expect(en.confirmImport, 'Confirm import');
    });

    test('statistics', () {
      expect(en.statsTitle, 'Statistics');
      expect(en.byStatus, 'By status');
      expect(en.byDirection, 'By direction');
      expect(en.byChannel, 'By channel');
      expect(en.noData, 'No data');
    });

    test('settings', () {
      expect(en.exportCsv, 'Export CSV');
      expect(en.exportXlsx, 'Export XLSX');
      expect(en.exportJobpack, 'Export .jobpack');
      expect(en.importJobpack, 'Import .jobpack');
      expect(en.clearAll, 'Clear all data');
      expect(en.checkUpdate, 'Check for updates');
      expect(en.versionText('1.2.0'), contains('1.2.0'));
    });

    test('controller messages', () {
      expect(en.savedApplication, 'Application saved');
      expect(en.deletedApplication, 'Application deleted');
      expect(en.savedStage, 'Stage saved');
      expect(en.deletedStage, 'Stage deleted');
      expect(en.clearedAll, 'Local data cleared');
      expect(en.exportFailed, 'Export failed');
    });

    test('Chinese fallback', () {
      final zh = AppStrings('zh');
      expect(zh.home, '首页');
      expect(zh.applications, '投递');
      expect(zh.import, '导入');
      expect(zh.statistics, '统计');
      expect(zh.settings, '设置');
    });

    test('stage type and result labels', () {
      expect(en.stageTypeLabel('一面'), 'First round');
      expect(en.stageTypeLabel('笔试'), 'Written test');
      expect(en.stageTypeLabel('HR 面'), 'HR round');
      expect(en.stageResultLabel('通过'), 'Passed');
      expect(en.stageResultLabel('待反馈'), 'Pending');
      // Chinese fallback: passthrough unchanged values
      final zh = AppStrings('zh');
      expect(zh.stageTypeLabel('一面'), '一面');
      expect(zh.stageResultLabel('通过'), '通过');
      // Unknown value passthrough
      expect(en.stageTypeLabel('未知'), '未知');
    });

    test('import row status labels', () {
      expect(en.importRowStatusLabel('importable'), 'Importable');
      expect(en.importRowStatusLabel('missingRequired'), 'Missing required fields');
      expect(en.importRowStatusLabel('suspectedDuplicate'), 'Suspected duplicate');
      expect(en.importRowStatusLabel('possibleDuplicate'), 'Possible duplicate');
      expect(en.importRowStatusLabel('invalidField'), 'Invalid field');
      // Chinese fallback
      final zh = AppStrings('zh');
      expect(zh.importRowStatusLabel('importable'), '可导入');
      expect(zh.importRowStatusLabel('missingRequired'), '缺少必填字段');
      // Unknown key passthrough
      expect(en.importRowStatusLabel('unknown_key'), 'unknown_key');
    });
  });
}
