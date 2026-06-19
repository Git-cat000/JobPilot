import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:jobpilot_mobile/main.dart';
import 'package:jobpilot_mobile/shared/state/app_controller.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets(
    'renders English UI outside the application edit form',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 切换语言会写入 SQLite。直接在测试体里 await 这条 ffi 写入会在
      // fake-async 区域内永久挂起（事件循环不推进），因此用 runAsync 把它
      // 放进真实异步区域完成，再 pumpAndSettle 触发重建。
      final controller =
          tester.widget<AppScope>(find.byType(AppScope)).notifier
              as AppController;
      await tester.runAsync(() => controller.setLanguage('en'));
      await tester.pumpAndSettle();

      // 底部导航切换为英文，且中文标签消失。
      expect(find.text('Home'), findsWidgets);
      expect(find.text('首页'), findsNothing);

      // 投递列表标题为英文。
      await tester.tap(find.text('Jobs'));
      await tester.pumpAndSettle();
      expect(find.text('Applications'), findsOneWidget);
      expect(find.text('投递记录'), findsNothing);

      // 统计页标题为英文（导航标签是 'Stats'，页面标题是 'Statistics'）。
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.text('Statistics'), findsOneWidget);

      // 设置页含检查更新行（'Settings' 同时出现在导航与标题，故只断言设置页
      // 独有的内容）。
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Check for updates'), findsOneWidget);

      // 版本号位于设置列表底部，向下滚动使其构建并可见。
      await tester.drag(
        find.byType(Scrollable).last,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1.2.0'), findsWidgets);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
