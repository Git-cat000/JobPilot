import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:jobpilot_mobile/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('shows phase one shell with five primary destinations', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('JobPilot'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('投递'), findsOneWidget);
    expect(find.text('导入'), findsOneWidget);
    expect(find.text('统计'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('opens applications and new application placeholder pages', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('投递'));
    await tester.pumpAndSettle();

    expect(find.text('投递记录'), findsOneWidget);
    expect(find.text('搜索公司、岗位或城市'), findsOneWidget);

    await tester.tap(find.text('新增'));
    await tester.pumpAndSettle();

    expect(find.text('新增投递'), findsOneWidget);
    expect(find.text('基本信息'), findsOneWidget);
  });
}
