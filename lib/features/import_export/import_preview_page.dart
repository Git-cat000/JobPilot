import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/application_record.dart';
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
          ...preview.rows.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${entry.value.record.companyName} · '
                            '${entry.value.record.jobTitle}',
                          ),
                        ),
                        IconButton(
                          tooltip: '编辑',
                          onPressed: () => _editRow(
                            context,
                            controller,
                            entry.key,
                            entry.value.record,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StatusPill(
                      label: entry.value.status.label,
                      color: _statusColor(entry.value.status),
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

  Future<void> _editRow(
    BuildContext context,
    AppController controller,
    int index,
    ApplicationRecord record,
  ) async {
    final company = TextEditingController(text: record.companyName);
    final title = TextEditingController(text: record.jobTitle);
    final city = TextEditingController(text: record.city);
    final channel = TextEditingController(text: record.channel);
    final applyDate = TextEditingController(text: record.applyDate);
    final remark = TextEditingController(text: record.remark);
    var status = record.status;
    var direction = record.jobDirection;
    final updated = await showDialog<ApplicationRecord>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑导入记录'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: company,
                  decoration: const InputDecoration(labelText: '公司名称 *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: '岗位名称 *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: city,
                  decoration: const InputDecoration(labelText: '城市'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: '状态'),
                  items: controller
                      .statusOptions()
                      .entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => status = value ?? status),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: direction,
                  decoration: const InputDecoration(labelText: '方向'),
                  items: controller
                      .directionOptions()
                      .entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => direction = value ?? direction),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: applyDate,
                  decoration: const InputDecoration(labelText: '投递日期'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: channel,
                  decoration: const InputDecoration(labelText: '渠道'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: remark,
                  decoration: const InputDecoration(labelText: '备注'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                record.copyWith(
                  companyName: company.text,
                  jobTitle: title.text,
                  city: city.text,
                  channel: channel.text,
                  applyDate: applyDate.text,
                  remark: remark.text,
                  status: status,
                  jobDirection: direction,
                ),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    for (final item in [company, title, city, channel, applyDate, remark]) {
      item.dispose();
    }
    if (updated != null) {
      controller.updatePreviewRecord(index, updated);
    }
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
