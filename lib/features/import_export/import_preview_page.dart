import 'package:flutter/material.dart';

import '../../core/enums/job_enums.dart';
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
    final updated = await showModalBottomSheet<ApplicationRecord>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _ImportRowEditSheet(record: record, controller: controller),
    );
    if (updated != null) {
      controller.updatePreviewRecord(index, updated);
    }
  }
}

class _ImportRowEditSheet extends StatefulWidget {
  const _ImportRowEditSheet({required this.record, required this.controller});

  final ApplicationRecord record;
  final AppController controller;

  @override
  State<_ImportRowEditSheet> createState() => _ImportRowEditSheetState();
}

class _ImportRowEditSheetState extends State<_ImportRowEditSheet> {
  late final TextEditingController company;
  late final TextEditingController title;
  late final TextEditingController city;
  late final TextEditingController channel;
  late final TextEditingController applyDate;
  late final TextEditingController remark;
  late String status;
  late String direction;

  @override
  void initState() {
    super.initState();
    company = TextEditingController(text: widget.record.companyName);
    title = TextEditingController(text: widget.record.jobTitle);
    city = TextEditingController(text: widget.record.city);
    channel = TextEditingController(text: widget.record.channel);
    applyDate = TextEditingController(text: widget.record.applyDate);
    remark = TextEditingController(text: widget.record.remark);
    status = widget.record.status;
    direction = widget.record.jobDirection;
  }

  @override
  void dispose() {
    for (final item in [company, title, city, channel, applyDate, remark]) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final statusOptions = widget.controller.statusOptions();
    final directionOptions = widget.controller.directionOptions();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '编辑导入记录',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '确认导入前可以修正识别错误',
                          style: TextStyle(color: AppTheme.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _SheetSection(
                      title: '必填信息',
                      children: [
                        TextField(
                          controller: company,
                          decoration: const InputDecoration(
                            labelText: '公司名称 *',
                            prefixIcon: Icon(Icons.apartment_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: title,
                          decoration: const InputDecoration(
                            labelText: '岗位名称 *',
                            prefixIcon: Icon(Icons.work_outline),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SheetSection(
                      title: '分类与状态',
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: statusOptions.containsKey(status)
                              ? status
                              : 'applied',
                          decoration: const InputDecoration(
                            labelText: '当前状态',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: statusOptions.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(
                                    statusLabel(
                                      entry.key,
                                      language: widget.controller.language,
                                      custom: widget.controller.customStatuses,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => status = value ?? status),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: directionOptions.containsKey(direction)
                              ? direction
                              : 'other',
                          decoration: const InputDecoration(
                            labelText: '岗位方向',
                            prefixIcon: Icon(Icons.explore_outlined),
                          ),
                          items: directionOptions.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(
                                    directionLabel(
                                      entry.key,
                                      language: widget.controller.language,
                                      custom:
                                          widget.controller.customDirections,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => direction = value ?? direction),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SheetSection(
                      title: '补充信息',
                      children: [
                        TextField(
                          controller: city,
                          decoration: const InputDecoration(
                            labelText: '城市',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: applyDate,
                          decoration: const InputDecoration(
                            labelText: '投递日期',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: channel,
                          decoration: const InputDecoration(
                            labelText: '渠道',
                            prefixIcon: Icon(Icons.public_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: remark,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: '备注',
                            prefixIcon: Icon(Icons.notes_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    Navigator.pop(
      context,
      widget.record.copyWith(
        companyName: company.text.trim(),
        jobTitle: title.text.trim(),
        city: city.text.trim(),
        channel: channel.text.trim(),
        applyDate: applyDate.text.trim(),
        remark: remark.text.trim(),
        status: status,
        jobDirection: direction,
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.75)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
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
