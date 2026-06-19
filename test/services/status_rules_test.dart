import 'package:flutter_test/flutter_test.dart';

import 'package:jobpilot_mobile/core/enums/job_enums.dart';
import 'package:jobpilot_mobile/features/classification/classification_service.dart';

void main() {
  group('process_terminated status', () {
    test('renders localized labels', () {
      expect(statusLabel('process_terminated'), '流程终止');
      expect(
        statusLabel('process_terminated', language: 'en'),
        'Process terminated',
      );
    });

    test('classifies explicit termination phrases before abandonment', () {
      final classifier = ClassificationService();
      expect(classifier.detectStatus('流程终止'), 'process_terminated');
      expect(classifier.detectStatus('终止流程'), 'process_terminated');
    });

    test('keeps generic abandonment keywords as abandoned', () {
      final classifier = ClassificationService();
      expect(classifier.detectStatus('放弃'), 'abandoned');
      expect(classifier.detectStatus('终止'), 'abandoned');
      expect(classifier.detectStatus('取消'), 'abandoned');
    });
  });
}
