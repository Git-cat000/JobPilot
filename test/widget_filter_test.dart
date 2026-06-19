import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_mobile/shared/widgets/filter_picker.dart';

void main() {
  const options = <(String, String)>[
    ('all', 'All status'),
    ('process_terminated', 'Process terminated'),
    ('rejected', 'Rejected'),
  ];

  testWidgets('opens sheet and selects an option', (tester) async {
    String value = 'all';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FilterPickerButton(
              value: value,
              options: options,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );

    // 未筛选时显示「全部」标签，且无清除图标。
    expect(find.text('All status'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);

    // 打开选择面板并选择「流程终止」。
    await tester.tap(find.text('All status'));
    await tester.pumpAndSettle();
    expect(find.text('Process terminated'), findsWidgets);
    await tester.tap(find.text('Process terminated').last);
    await tester.pumpAndSettle();

    // 选择生效后按钮进入激活态，显示当前标签与清除图标。
    expect(value, 'process_terminated');
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('clear icon resets to all', (tester) async {
    String value = 'rejected';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FilterPickerButton(
              value: value,
              options: options,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.close), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(value, 'all');
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('iOS picker uses localized cancel text', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterPickerButton(
            value: 'all',
            options: options,
            cancelText: 'Cancel',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('All status'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('取消'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
