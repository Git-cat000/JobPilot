import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/widgets/app_card.dart';
import 'services/import_parser.dart';

class ImportPreviewPage extends StatelessWidget {
  const ImportPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final preview = controller.currentPreview;
    if (preview == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('导入预览')),
        body: const Center(child: Text('暂无导入预览')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('导入预览')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _PreviewMetric(label: '总行数', value: '${preview.totalRows}'),
              const SizedBox(width: 10),
              _PreviewMetric(label: '可导入', value: '${preview.importableRows}'),
              const SizedBox(width: 10),
              _PreviewMetric(label: '错误', value: '${preview.failedRows}'),
            ],
          ),
          const SizedBox(height: 16),
          const SectionTitle('字段映射结果'),
          const SizedBox(height: 10),
          AppCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: preview.mapping.entries
                  .map(
                    (entry) => StatusPill(
                      label: '${entry.key} -> ${entry.value}',
                      color: AppTheme.primary,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('记录状态'),
          const SizedBox(height: 10),
          ...preview.rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${row.record.companyName} · ${row.record.jobTitle}'),
                    const SizedBox(height: 8),
                    StatusPill(
                      label: row.status.label,
                      color: _statusColor(row.status),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消导入'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('确认导入？'),
                        content: Text(
                          '将写入 ${preview.importableRows} 条记录。疑似重复会按预览结果一并导入，请确认。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('确认'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await controller.confirmImport();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: const Text('确认导入'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(ImportRowStatus status) {
    return switch (status) {
      ImportRowStatus.importable => AppTheme.success,
      ImportRowStatus.suspectedDuplicate => AppTheme.warning,
      ImportRowStatus.possibleDuplicate => AppTheme.warning,
      ImportRowStatus.missingRequired => AppTheme.danger,
      ImportRowStatus.invalidField => AppTheme.danger,
    };
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(label, style: const TextStyle(color: AppTheme.secondaryText)),
          ],
        ),
      ),
    );
  }
}
