import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_mobile/data/models/application_record.dart';
import 'package:jobpilot_mobile/features/settings/services/export_service.dart';

void main() {
  test('builds csv export with readable Chinese headers', () {
    final csvText = ExportService.buildCsv([
      ApplicationRecord.create(
        companyName: '华为',
        jobTitle: 'AI算法工程师',
        city: '深圳',
        status: 'first_interview',
        jobDirection: 'ai_algorithm',
      ),
    ]);

    expect(csvText, contains('公司名称'));
    expect(csvText, contains('华为'));
    expect(csvText, contains('一面'));
    expect(csvText, contains('AI / 算法'));
  });
}
