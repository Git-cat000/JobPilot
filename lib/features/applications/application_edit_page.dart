import 'package:flutter/material.dart';

import '../../core/enums/job_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/application_record.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/widgets/app_card.dart';

class ApplicationEditPage extends StatefulWidget {
  const ApplicationEditPage({super.key});

  static const routeName = '/applications/edit';

  @override
  State<ApplicationEditPage> createState() => _ApplicationEditPageState();
}

class _ApplicationEditPageState extends State<ApplicationEditPage> {
  final company = TextEditingController();
  final title = TextEditingController();
  final city = TextEditingController();
  final channel = TextEditingController();
  final applyDate = TextEditingController();
  final nextFollowDate = TextEditingController();
  final jdLink = TextEditingController();
  final resumeVersion = TextEditingController();
  final salaryRange = TextEditingController();
  final remark = TextEditingController();
  String status = 'applied';
  String direction = 'other';
  String priority = 'B';
  ApplicationRecord? original;
  bool didLoadArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (didLoadArgs) {
      return;
    }
    didLoadArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    final controller = AppScope.watch(context);
    final record = args is String
        ? controller.applications.where((item) => item.id == args).firstOrNull
        : args is ApplicationRecord
        ? args
        : null;
    if (record != null) {
      original = record;
      company.text = record.companyName;
      title.text = record.jobTitle;
      city.text = record.city;
      channel.text = record.channel;
      applyDate.text = record.applyDate;
      nextFollowDate.text = record.nextFollowDate;
      jdLink.text = record.jdLink;
      resumeVersion.text = record.resumeVersion;
      salaryRange.text = record.salaryRange;
      remark.text = record.remark;
      status = record.status;
      direction = record.jobDirection;
      priority = record.priority;
    }
  }

  @override
  void dispose() {
    for (final item in [
      company,
      title,
      city,
      channel,
      applyDate,
      nextFollowDate,
      jdLink,
      resumeVersion,
      salaryRange,
      remark,
    ]) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    return Scaffold(
      appBar: AppBar(title: Text(original == null ? '新增投递' : '编辑投递')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FormSection(
            title: '基本信息',
            children: [
              TextField(
                controller: company,
                decoration: const InputDecoration(labelText: '公司名称 *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: '岗位名称 *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: city,
                decoration: const InputDecoration(labelText: '城市'),
              ),
              const SizedBox(height: 12),
              _OptionPickerField(
                label: '岗位方向',
                value: directionLabel(
                  direction,
                  language: controller.language,
                  custom: controller.customDirections,
                ),
                onTap: () async {
                  final value = await _showOptionPicker(
                    context,
                    title: '选择岗位方向',
                    currentValue: direction,
                    isStatus: false,
                  );
                  if (value != null && mounted) {
                    setState(() => direction = value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FormSection(
            title: '求职状态',
            children: [
              _OptionPickerField(
                label: '当前状态',
                value: statusLabel(
                  status,
                  language: controller.language,
                  custom: controller.customStatuses,
                ),
                onTap: () async {
                  final value = await _showOptionPicker(
                    context,
                    title: '选择求职状态',
                    currentValue: status,
                    isStatus: true,
                  );
                  if (value != null && mounted) {
                    setState(() => status = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: '优先级'),
                items: priorityLabels.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text('${entry.key} · ${entry.value}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => priority = value ?? 'B'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FormSection(
            title: '投递信息',
            children: [
              TextField(
                controller: channel,
                decoration: const InputDecoration(labelText: '投递渠道'),
              ),
              const SizedBox(height: 12),
              _DateField(controller: applyDate, label: '投递日期'),
              const SizedBox(height: 12),
              TextField(
                controller: jdLink,
                decoration: const InputDecoration(labelText: 'JD 链接'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FormSection(
            title: '跟进信息',
            children: [
              _DateField(controller: nextFollowDate, label: '下次跟进日期'),
              const SizedBox(height: 12),
              TextField(
                controller: resumeVersion,
                decoration: const InputDecoration(labelText: '简历版本'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: salaryRange,
                decoration: const InputDecoration(labelText: '薪资范围'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FormSection(
            title: '备注',
            children: [
              TextField(
                controller: remark,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(labelText: '复盘、准备事项或补充信息'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('保存投递'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (company.text.trim().isEmpty || title.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('公司名称和岗位名称为必填')));
      return;
    }
    final record =
        original?.copyWith(
          companyName: company.text,
          jobTitle: title.text,
          jobDirection: direction,
          city: city.text,
          channel: channel.text,
          status: status,
          priority: priority,
          applyDate: applyDate.text,
          nextFollowDate: nextFollowDate.text,
          jdLink: jdLink.text,
          resumeVersion: resumeVersion.text,
          salaryRange: salaryRange.text,
          remark: remark.text,
        ) ??
        ApplicationRecord.create(
          companyName: company.text,
          jobTitle: title.text,
          jobDirection: direction,
          city: city.text,
          channel: channel.text,
          status: status,
          priority: priority,
          applyDate: applyDate.text,
          nextFollowDate: nextFollowDate.text,
          jdLink: jdLink.text,
          resumeVersion: resumeVersion.text,
          salaryRange: salaryRange.text,
          remark: remark.text,
        );
    await AppScope.watch(context).saveApplication(record);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<String?> _showOptionPicker(
    BuildContext context, {
    required String title,
    required String currentValue,
    required bool isStatus,
  }) async {
    final controller = AppScope.watch(context);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _OptionPickerSheet(
        title: title,
        currentValue: currentValue,
        isStatus: isStatus,
        controller: controller,
      ),
    );
  }
}

class _OptionPickerField extends StatelessWidget {
  const _OptionPickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.keyboard_arrow_right_rounded),
        ),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _OptionPickerSheet extends StatefulWidget {
  const _OptionPickerSheet({
    required this.title,
    required this.currentValue,
    required this.isStatus,
    required this.controller,
  });

  final String title;
  final String currentValue;
  final bool isStatus;
  final AppController controller;

  @override
  State<_OptionPickerSheet> createState() => _OptionPickerSheetState();
}

class _OptionPickerSheetState extends State<_OptionPickerSheet> {
  final text = TextEditingController();

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.isStatus
        ? widget.controller.statusOptions()
        : widget.controller.directionOptions();
    final customOptions = widget.isStatus
        ? widget.controller.customStatuses
        : widget.controller.customDirections;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: SafeArea(
        top: false,
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
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '轻点选择，自定义项可左滑删除',
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
            Flexible(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.border.withValues(alpha: 0.75),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  itemCount: options.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 52,
                    color: AppTheme.border.withValues(alpha: 0.7),
                  ),
                  itemBuilder: (context, index) {
                    final entry = options.entries.elementAt(index);
                    final isCustom = customOptions.containsKey(entry.key);
                    final label = widget.isStatus
                        ? statusLabel(
                            entry.key,
                            language: widget.controller.language,
                            custom: widget.controller.customStatuses,
                          )
                        : directionLabel(
                            entry.key,
                            language: widget.controller.language,
                            custom: widget.controller.customDirections,
                          );
                    final tile = ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      leading: _OptionIcon(isCustom: isCustom),
                      title: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: isCustom ? const Text('自定义选项') : null,
                      trailing: entry.key == widget.currentValue
                          ? const Icon(
                              Icons.check_circle,
                              color: AppTheme.primary,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, entry.key),
                    );
                    if (!isCustom) {
                      return tile;
                    }
                    return Dismissible(
                      key: ValueKey('${widget.isStatus}-${entry.key}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.danger,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        if (widget.isStatus) {
                          await widget.controller.deleteCustomStatus(entry.key);
                        } else {
                          await widget.controller.deleteCustomDirection(
                            entry.key,
                          );
                        }
                        if (!mounted || !context.mounted) {
                          return false;
                        }
                        if (entry.key == widget.currentValue) {
                          Navigator.pop(
                            context,
                            widget.isStatus ? 'applied' : 'other',
                          );
                          return false;
                        }
                        setState(() {});
                        return true;
                      },
                      child: tile,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.border.withValues(alpha: 0.75),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isStatus ? '添加自定义状态' : '添加自定义方向',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '添加后会自动选中，可在上方列表左滑删除。',
                      style: TextStyle(color: AppTheme.secondaryText),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: text,
                      decoration: InputDecoration(
                        hintText: widget.isStatus ? '例如：终面沟通' : '例如：嵌入式软件',
                      ),
                      onSubmitted: (_) => _addAndSelect(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _addAndSelect,
                        icon: const Icon(Icons.add),
                        label: const Text('添加并选中'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAndSelect() async {
    final label = text.text.trim();
    if (label.isEmpty) {
      return;
    }
    final value = widget.isStatus
        ? await widget.controller.addCustomStatus(label)
        : await widget.controller.addCustomDirection(label);
    if (mounted) {
      Navigator.pop(context, value);
    }
  }
}

class _OptionIcon extends StatelessWidget {
  const _OptionIcon({required this.isCustom});

  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: (isCustom ? AppTheme.success : AppTheme.primary)
          .withValues(alpha: 0.10),
      child: Icon(
        isCustom ? Icons.tune_outlined : Icons.label_outline,
        size: 18,
        color: isCustom ? AppTheme.success : AppTheme.primary,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: DateTime.now(),
        );
        if (picked != null) {
          controller.text = picked.toIso8601String().split('T').first;
        }
      },
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
