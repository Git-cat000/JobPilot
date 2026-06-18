import 'package:flutter/material.dart';

import '../../core/enums/job_enums.dart';
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
              DropdownButtonFormField<String>(
                initialValue: direction,
                decoration: const InputDecoration(labelText: '岗位方向'),
                items: directionLabels.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => direction = value ?? 'other'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FormSection(
            title: '求职状态',
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: '当前状态'),
                items: statusLabels.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => status = value ?? 'applied'),
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
