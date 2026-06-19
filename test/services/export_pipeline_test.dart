import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
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

  test('jobpack metadata uses the active app version', () async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = await Directory.systemTemp.createTemp(
      'jobpilot_export_test_',
    );
    final databaseFile = File('${tempDir.path}/data.sqlite')
      ..writeAsBytesSync([1, 2, 3, 4]);
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        null,
      ),
    );

    final jobpack = await ExportService().exportJobpack(
      databasePath: databaseFile.path,
      applicationCount: 2,
      stageCount: 1,
      appVersion: '1.2.0+3',
    );

    final archive = ZipDecoder().decodeBytes(await jobpack.readAsBytes());
    final metadata =
        jsonDecode(
              utf8.decode(
                archive.files
                        .singleWhere((file) => file.name == 'metadata.json')
                        .content
                    as List<int>,
              ),
            )
            as Map<String, dynamic>;
    final version =
        jsonDecode(
              utf8.decode(
                archive.files
                        .singleWhere((file) => file.name == 'version.json')
                        .content
                    as List<int>,
              ),
            )
            as Map<String, dynamic>;

    expect(metadata['version'], '1.2.0+3');
    expect(version['app_version'], '1.2.0+3');
  });
}
