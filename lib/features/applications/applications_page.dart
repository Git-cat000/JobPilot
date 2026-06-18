import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/enums/job_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/application_record.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/widgets/adaptive.dart';
import '../../shared/widgets/app_card.dart';
import 'application_detail_page.dart';
import 'application_edit_page.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key});

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  String query = '';
  String status = 'all';
  String direction = 'all';
  bool selecting = false;
  final selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final strings = AppStrings(controller.language);
    final records = controller.applications.where(_matches).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdaptiveTabHeader(
          title: strings.jobRecords,
          actions: [
            FilledButton.tonalIcon(
              onPressed: () {
                setState(() {
                  selecting = !selecting;
                  selectedIds.clear();
                });
              },
              icon: Icon(selecting ? Icons.close : Icons.checklist_outlined),
              label: Text(selecting ? strings.done : strings.select),
            ),
            const SizedBox(width: 8),
            if (!selecting)
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(
                    context,
                  ).pushNamed(ApplicationEditPage.routeName);
                },
                icon: const Icon(Icons.add),
                label: Text(strings.add),
              ),
          ],
        ),
        if (selecting) ...[
          const SizedBox(height: 10),
          AppCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '已选择 ${selectedIds.length} 项',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: records.isEmpty
                      ? null
                      : () => _toggleSelectAll(records),
                  icon: Icon(
                    _allVisibleSelected(records)
                        ? Icons.remove_done_outlined
                        : Icons.done_all_outlined,
                  ),
                  label: Text(_allVisibleSelected(records) ? '取消全选' : '全选'),
                ),
                FilledButton.icon(
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () => _confirmBulkDelete(context, controller),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: strings.searchHint,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DropdownMenu<String>(
              initialSelection: status,
              onSelected: (value) => setState(() => status = value ?? 'all'),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'all', label: strings.allStatus),
                ...controller.statusOptions().entries.map(
                  (entry) => DropdownMenuEntry(
                    value: entry.key,
                    label: statusLabel(
                      entry.key,
                      language: controller.language,
                      custom: controller.customStatuses,
                    ),
                  ),
                ),
              ],
            ),
            DropdownMenu<String>(
              initialSelection: direction,
              onSelected: (value) => setState(() => direction = value ?? 'all'),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'all', label: strings.allDirection),
                ...controller.directionOptions().entries.map(
                  (entry) => DropdownMenuEntry(
                    value: entry.key,
                    label: directionLabel(
                      entry.key,
                      language: controller.language,
                      custom: controller.customDirections,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (records.isEmpty)
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.inbox_outlined, color: AppTheme.secondaryText),
                const SizedBox(width: 12),
                Expanded(child: Text(strings.noMatch)),
              ],
            ),
          )
        else
          ...records.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ApplicationCard(
                record: record,
                selecting: selecting,
                selected: selectedIds.contains(record.id),
                onSelected: () {
                  setState(() {
                    selectedIds.contains(record.id)
                        ? selectedIds.remove(record.id)
                        : selectedIds.add(record.id);
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  bool _matches(ApplicationRecord record) {
    final q = query.trim().toLowerCase();
    final text = [
      record.companyName,
      record.jobTitle,
      record.city,
    ].join(' ').toLowerCase();
    final queryOk = q.isEmpty || text.contains(q);
    final statusOk = status == 'all' || record.status == status;
    final directionOk = direction == 'all' || record.jobDirection == direction;
    return queryOk && statusOk && directionOk;
  }

  bool _allVisibleSelected(List<ApplicationRecord> records) {
    return records.isNotEmpty &&
        records.every((record) => selectedIds.contains(record.id));
  }

  void _toggleSelectAll(List<ApplicationRecord> records) {
    setState(() {
      if (_allVisibleSelected(records)) {
        for (final record in records) {
          selectedIds.remove(record.id);
        }
      } else {
        selectedIds.addAll(records.map((record) => record.id));
      }
    });
  }

  Future<void> _confirmBulkDelete(
    BuildContext context,
    AppController controller,
  ) async {
    final ok = await showAdaptiveConfirm(
      context,
      title: '批量删除？',
      content: '将删除 ${selectedIds.length} 条投递记录及其流程记录。',
      confirmText: '删除',
      destructive: true,
    );
    if (ok) {
      await controller.deleteApplications(selectedIds);
      if (!mounted) {
        return;
      }
      setState(() {
        selecting = false;
        selectedIds.clear();
      });
    }
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.record,
    required this.selecting,
    required this.selected,
    required this.onSelected,
  });

  final ApplicationRecord record;
  final bool selecting;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: selecting
            ? onSelected
            : () {
                Navigator.of(context).pushNamed(
                  ApplicationDetailPage.routeName,
                  arguments: record.id,
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selecting)
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2),
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => onSelected(),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.companyName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        StatusPill(
                          label: statusLabel(
                            record.status,
                            language: controller.language,
                            custom: controller.customStatuses,
                          ),
                          color: _statusColor(record.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(record.jobTitle),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusPill(
                          label: directionLabel(
                            record.jobDirection,
                            language: controller.language,
                            custom: controller.customDirections,
                          ),
                          color: AppTheme.success,
                        ),
                        StatusPill(
                          label: 'P${record.priority}',
                          color: _priorityColor(record.priority),
                        ),
                        if (record.city.isNotEmpty)
                          StatusPill(
                            label: record.city,
                            color: const Color(0xFF0EA5E9),
                          ),
                        if (record.channel.isNotEmpty)
                          StatusPill(
                            label: record.channel,
                            color: const Color(0xFF8B5CF6),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusPill(
                          label: record.applyDate.isEmpty
                              ? '投递日期未填'
                              : record.applyDate,
                          color: AppTheme.secondaryText,
                        ),
                        StatusPill(
                          label: record.nextFollowDate.isEmpty
                              ? '待跟进'
                              : '跟进 ${record.nextFollowDate}',
                          color: record.nextFollowDate.isEmpty
                              ? AppTheme.warning
                              : AppTheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'offer' || 'signed' => AppTheme.success,
      'rejected' || 'abandoned' => AppTheme.danger,
      'written_test' ||
      'first_interview' ||
      'second_interview' ||
      'final_interview' ||
      'hr_interview' => AppTheme.warning,
      _ => AppTheme.primary,
    };
  }

  Color _priorityColor(String priority) {
    return switch (priority) {
      'S' => AppTheme.danger,
      'A' => AppTheme.warning,
      'B' => AppTheme.primary,
      _ => AppTheme.secondaryText,
    };
  }
}
