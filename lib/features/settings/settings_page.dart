import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/widgets/adaptive.dart';
import '../../shared/widgets/app_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final strings = AppStrings(controller.language);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdaptiveTabHeader(title: strings.settings),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('语言 / Language'),
              const SizedBox(height: 8),
              AdaptiveSegmentedControl<String>(
                value: controller.language,
                options: [
                  ('zh', strings.chinese),
                  ('en', strings.english),
                ],
                onChanged: controller.setLanguage,
              ),
              const SizedBox(height: 14),
              _SettingsAction(
                icon: Icons.file_download_outlined,
                label: controller.language == 'en' ? 'Export CSV' : '导出 CSV',
                onTap: () => _export(context, controller.exportCsv()),
              ),
              _SettingsAction(
                icon: Icons.grid_on_outlined,
                label: controller.language == 'en' ? 'Export XLSX' : '导出 XLSX',
                onTap: () => _export(context, controller.exportXlsx()),
              ),
              _SettingsAction(
                icon: Icons.inventory_2_outlined,
                label: controller.language == 'en'
                    ? 'Export .jobpack'
                    : '导出 .jobpack',
                onTap: () => _export(context, controller.exportJobpack()),
              ),
              _SettingsAction(
                icon: Icons.restore_outlined,
                label: controller.language == 'en'
                    ? 'Import .jobpack'
                    : '导入 .jobpack',
                onTap: () => _confirmRestore(context, controller),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('本地数据'),
              const SizedBox(height: 8),
              const Text('数据默认保存在本机 SQLite。清空数据和备份恢复都会二次确认。'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmClear(context, controller),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('清空所有数据'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'JobPilot 1.0.0 · 离线优先',
          style: TextStyle(color: AppTheme.secondaryText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, Future<Object> future) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await future;
    final path = (file as dynamic).path as String;
    messenger.showSnackBar(SnackBar(content: Text('已导出到：$path')));
  }

  Future<void> _confirmClear(
    BuildContext context,
    AppController controller,
  ) async {
    final ok = await showAdaptiveConfirm(
      context,
      title: '清空所有数据？',
      content: '此操作会删除所有投递记录和流程记录，且不可撤销。',
      confirmText: '清空',
      destructive: true,
    );
    if (ok) {
      await controller.clearAll();
    }
  }

  Future<void> _confirmRestore(
    BuildContext context,
    AppController controller,
  ) async {
    final ok = await showAdaptiveConfirm(
      context,
      title: '导入备份？',
      content: '导入 .jobpack 可能覆盖当前本地数据。恢复失败时会保留原数据库备份。',
      confirmText: '选择备份',
    );
    if (ok) {
      await controller.importJobpack();
    }
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
