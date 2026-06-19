import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 当前平台是否为 iOS。所有 iOS 化分支都以此为开关，
/// 安卓端（含测试宿主 Windows/macOS）与 Web 始终走 Material 原路径，行为不变。
bool get isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// 顶部大标题头部：用于五个 Tab 页。
///
/// iOS：34pt 粗体大标题 + 灰色副标题，左对齐，右上角放操作按钮，
/// 贴近 iOS 大标题样式。
/// 安卓：完全复刻原有 `headlineSmall` w900 标题行布局，视觉不变。
class AdaptiveTabHeader extends StatelessWidget {
  const AdaptiveTabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final titleChild = isIos
        ? Text(
            title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.1,
              color: AppTheme.text,
            ),
          )
        : Text(
            title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          );

    final subtitleChild = subtitle == null
        ? null
        : isIos
        ? Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.secondaryText,
            ),
          )
        : Text(
            subtitle!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.secondaryText),
          );

    final leading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleChild,
        if (subtitleChild != null) ...[
          const SizedBox(height: 6),
          subtitleChild,
        ],
      ],
    );

    if (isIos) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leading),
            ...actions,
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: leading),
        ...actions,
      ],
    );
  }
}

/// 带顶部导航栏的页面骨架：用于详情 / 编辑 / 导入预览等被 push 的页面。
///
/// iOS：`CupertinoPageScaffold` + `CupertinoNavigationBar`，返回按钮自动出现，
/// 半透明导航栏。安卓：`Scaffold` + `AppBar`，与原有实现一致。
class AdaptivePageScaffold extends StatelessWidget {
  const AdaptivePageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    if (isIos) {
      return CupertinoPageScaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          backgroundColor: const Color(0xFFF7F8FA).withValues(alpha: 0.92),
          border: const Border(
            bottom: BorderSide(color: AppTheme.border, width: 0.5),
          ),
          trailing: actions == null || actions!.isEmpty
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: actions!),
        ),
        child: body,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: body,
    );
  }
}

/// 自适应确认弹窗。
///
/// iOS：`CupertinoAlertDialog`，支持 `destructive` 红色确认按钮。
/// 安卓：`AlertDialog` + `TextButton`/`FilledButton`，按钮文案与原实现一致。
Future<bool> showAdaptiveConfirm(
  BuildContext context, {
  required String title,
  required String content,
  String cancelText = '取消',
  String confirmText = '确认',
  bool destructive = false,
}) async {
  if (isIos) {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 自适应日期选择器。
///
/// iOS：底部弹出 `CupertinoDatePicker` 滚轮 + 「完成」按钮。
/// 安卓：`showDatePicker`，范围与原实现一致（2020–2100）。
Future<DateTime?> showAdaptiveDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  if (isIos) {
    var picked = initialDate;
    var confirmed = false;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                CupertinoButton(
                  onPressed: () {
                    confirmed = true;
                    Navigator.pop(ctx);
                  },
                  child: const Text('完成'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (date) => picked = date,
              ),
            ),
          ],
        ),
      ),
    );
    return confirmed ? picked : null;
  }
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2020),
    lastDate: lastDate ?? DateTime(2100),
  );
}

/// 自适应分段选择器。
///
/// iOS：`CupertinoSlidingSegmentedControl`。安卓：`SegmentedButton`。
class AdaptiveSegmentedControl<T extends Object> extends StatelessWidget {
  const AdaptiveSegmentedControl({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    if (isIos) {
      return CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        onValueChanged: (v) {
          if (v != null) onChanged(v);
        },
        children: {
          for (final option in options)
            option.$1: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Text(option.$2),
            ),
        },
      );
    }
    return SegmentedButton<T>(
      segments: [
        for (final option in options) ButtonSegment(value: option.$1, label: Text(option.$2)),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
