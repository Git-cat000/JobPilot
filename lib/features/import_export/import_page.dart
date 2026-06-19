import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/widgets/adaptive.dart';
import '../../shared/widgets/app_card.dart';
import 'import_preview_page.dart';

class ImportPage extends StatelessWidget {
  const ImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final strings = AppStrings(controller.language);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdaptiveTabHeader(
          title: strings.import,
          subtitle: strings.importSubtitle,
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.table_chart_outlined, color: AppTheme.primary),
              const SizedBox(height: 12),
              Text(
                strings.chooseFileTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(strings.chooseFileHint),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  final preview = await controller.pickAndPreviewImport();
                  if (preview != null && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ImportPreviewPage(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(strings.chooseFilePreview),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionTitle(strings.fieldMappingTitle),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.mappingCompany),
              const SizedBox(height: 8),
              Text(strings.mappingTitle),
              const SizedBox(height: 8),
              Text(strings.mappingStatus),
            ],
          ),
        ),
      ],
    );
  }
}
