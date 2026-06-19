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
              SectionTitle(strings.languageSection),
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
                label: strings.exportCsv,
                onTap: () => _export(context, controller.exportCsv()),
              ),
              _SettingsAction(
                icon: Icons.grid_on_outlined,
                label: strings.exportXlsx,
                onTap: () => _export(context, controller.exportXlsx()),
              ),
              _SettingsAction(
                icon: Icons.inventory_2_outlined,
                label: strings.exportJobpack,
                onTap: () => _export(context, controller.exportJobpack()),
              ),
              _SettingsAction(
                icon: Icons.restore_outlined,
                label: strings.importJobpack,
                onTap: () => _confirmRestore(context, controller),
              ),
              _SettingsAction(
                icon: Icons.system_update_outlined,
                label: strings.checkUpdate,
                onTap: () => controller.openUpdatesPage(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(strings.localData),
              const SizedBox(height: 8),
              Text(strings.localDataDesc),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmClear(context, controller),
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(strings.clearAll),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          strings.versionText(controller.version),
          style: const TextStyle(color: AppTheme.secondaryText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, Future<Object> future) async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppStrings(AppScope.watch(context).language);
    try {
      final file = await future;
      final path = (file as dynamic).path as String;
      messenger.showSnackBar(SnackBar(content: Text(strings.exportedTo(path))));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(strings.exportFailed)));
    }
  }

  Future<void> _confirmClear(
    BuildContext context,
    AppController controller,
  ) async {
    final strings = AppStrings(controller.language);
    final ok = await showAdaptiveConfirm(
      context,
      title: strings.clearAllTitle,
      content: strings.clearAllContent,
      confirmText: strings.clearAction,
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
    final strings = AppStrings(controller.language);
    final ok = await showAdaptiveConfirm(
      context,
      title: strings.restoreTitle,
      content: strings.restoreContent,
      confirmText: strings.restoreAction,
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
