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

  group('classification conflicts', () {
    final classifier = ClassificationService();

    test('"未通过" classifies as rejected, not offer', () {
      // 「通过」是 offer 的关键词，但「未通过」应被 rejected 的更长关键词命中。
      expect(classifier.detectStatus('未通过'), 'rejected');
      expect(classifier.detectStatus('面试未通过'), 'rejected');
      // 裸「通过」仍归 offer。
      expect(classifier.detectStatus('通过'), 'offer');
    });

    test('"简历筛选" classifies as resume_screen, not applied', () {
      // 该关键词曾同时出现在 applied 与 resume_screen，导致被 applied 吞掉。
      expect(classifier.detectStatus('简历筛选'), 'resume_screen');
      expect(classifier.detectStatus('简历筛选中'), 'resume_screen');
    });

    test('"谈薪中"/"薪资沟通" classify as offer_negotiation', () {
      // 不应被 hr_interview 的短词「谈薪」/「薪资」遮蔽。
      expect(classifier.detectStatus('谈薪中'), 'offer_negotiation');
      expect(classifier.detectStatus('薪资沟通'), 'offer_negotiation');
      // 裸「谈薪」仍归 hr_interview。
      expect(classifier.detectStatus('谈薪'), 'hr_interview');
    });
  });
}
