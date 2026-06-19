import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'adaptive.dart';

/// 紧凑的圆角筛选按钮。
///
/// 显示当前选项的标签：未筛选时为描边中性样式；筛选生效时为品牌色淡填充，
/// 并带一个清除小图标，点击直接重置为「全部」。点击按钮主体打开
/// [showAdaptiveFilterPicker] 选择面板。
class FilterPickerButton extends StatelessWidget {
  const FilterPickerButton({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  /// 当前值；`options` 中第一个 value 约定为「全部」。
  final String value;

  /// 可选项：`(value, label)`，第一项应为「全部」。
  final List<(String, String)> options;

  /// 选择回调。
  final ValueChanged<String> onChanged;

  bool get _isActive => value != allValue;

  String get allValue => options.first.$1;

  String get _currentLabel {
    for (final option in options) {
      if (option.$1 == value) return option.$2;
    }
    return options.first.$2;
  }

  @override
  Widget build(BuildContext context) {
    final active = _isActive;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final selected = await showAdaptiveFilterPicker<String>(
            context,
            value: value,
            options: options,
          );
          if (selected != null) onChanged(selected);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primary.withValues(alpha: 0.10)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? AppTheme.primary.withValues(alpha: 0.45)
                  : AppTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_outlined,
                size: 16,
                color: active ? AppTheme.primary : AppTheme.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                _currentLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppTheme.primary : AppTheme.text,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => onChanged(allValue),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(
                      Icons.close,
                      size: 15,
                      color: AppTheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 自适应筛选选择面板。
///
/// iOS：`CupertinoActionSheet`，每个选项一个 action，附带「取消」。
/// 安卓/Web：圆角模态底部表单，`RadioListTile` 单选，顶部标题。
///
/// 选项列表由调用方提供（应包含「全部」）。返回被选中的 value；用户取消
///（点击遮罩或取消按钮）时返回 `null`。
Future<T?> showAdaptiveFilterPicker<T>(
  BuildContext context, {
  required T value,
  required List<(T, String)> options,
}) async {
  if (isIos) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          for (final option in options)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, option.$1),
              child: Text(option.$2),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              ListTile(
                onTap: () => Navigator.pop(ctx, option.$1),
                title: Text(option.$2),
                trailing: option.$1 == value
                    ? const Icon(Icons.check, color: AppTheme.primary)
                    : null,
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
