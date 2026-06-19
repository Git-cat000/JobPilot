import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 集中的状态颜色选择：所有展示状态色的页面都应走这里，避免散落 switch。
/// process_terminated / rejected / abandoned 共用 danger 色。
Color statusColor(String status) {
  return switch (status) {
    'offer' || 'signed' => AppTheme.success,
    'rejected' || 'abandoned' || 'process_terminated' => AppTheme.danger,
    'written_test' ||
    'first_interview' ||
    'second_interview' ||
    'final_interview' ||
    'hr_interview' =>
      AppTheme.warning,
    _ => AppTheme.primary,
  };
}

/// 终结类状态：用于统计「进行中」口径——offer/已签约/拒绝/放弃/流程终止 不计入进行中。
const terminatedStatuses = [
  'offer',
  'signed',
  'rejected',
  'abandoned',
  'process_terminated',
];

class AppTheme {
  static const background = Color(0xFFF6F7F9);
  static const primary = Color(0xFF2563EB);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const text = Color(0xFF111827);
  static const secondaryText = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      surface: Colors.white,
      surfaceContainerHighest: background,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC'],
      // iOS 端使用 Cupertino 横向推进转场并支持右滑返回；
      // 安卓端保持 Material 3 默认的 Zoom 转场，行为不变。
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFFF7F8FA),
        foregroundColor: text,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border.withValues(alpha: 0.75)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        indicatorColor: primary.withValues(alpha: 0.10),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
    );
  }
}
