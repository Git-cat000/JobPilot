import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_mobile/core/enums/job_enums.dart';
import 'package:jobpilot_mobile/shared/state/demo_app_controller.dart';

void main() {
  test('web demo seeds only standard statuses and directions', () async {
    final controller = DemoAppController();
    await controller.init();

    expect(controller.isDemo, isTrue);
    expect(controller.applications, isNotEmpty);
    expect(
      controller.applications.map((record) => record.status),
      contains('process_terminated'),
    );
    expect(
      controller.applications.every(
        (record) => statusLabels.containsKey(record.status),
      ),
      isTrue,
    );
    expect(
      controller.applications.every(
        (record) => directionLabels.containsKey(record.jobDirection),
      ),
      isTrue,
    );
  });

  test('web demo version is 1.2.0+3', () async {
    final controller = DemoAppController();
    await controller.init();
    expect(controller.version, '1.2.0+3');
  });

  test('web demo remains read-only and localizes its notice', () async {
    final controller = DemoAppController();
    await controller.init();
    final originalCount = controller.applications.length;

    await controller.deleteApplication(controller.applications.first.id);
    expect(controller.applications, hasLength(originalCount));
    expect(controller.message, contains('只读 Web 演示'));

    await controller.setLanguage('en');
    await controller.clearAll();
    expect(controller.applications, hasLength(originalCount));
    expect(controller.message, contains('Read-only Web demo'));
  });
}
