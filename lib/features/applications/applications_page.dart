import 'package:flutter/material.dart';

import '../../core/enums/job_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/application_record.dart';
import '../../shared/state/app_controller.dart';
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

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final records = controller.applications.where(_matches).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '投递记录',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.of(
                  context,
                ).pushNamed(ApplicationEditPage.routeName);
              },
              icon: const Icon(Icons.add),
              label: const Text('新增'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            hintText: '搜索公司、岗位或城市',
            prefixIcon: Icon(Icons.search),
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
                const DropdownMenuEntry(value: 'all', label: '全部状态'),
                ...statusLabels.entries.map(
                  (entry) =>
                      DropdownMenuEntry(value: entry.key, label: entry.value),
                ),
              ],
            ),
            DropdownMenu<String>(
              initialSelection: direction,
              onSelected: (value) => setState(() => direction = value ?? 'all'),
              dropdownMenuEntries: [
                const DropdownMenuEntry(value: 'all', label: '全部方向'),
                ...directionLabels.entries.map(
                  (entry) =>
                      DropdownMenuEntry(value: entry.key, label: entry.value),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (records.isEmpty)
          const AppCard(
            child: Row(
              children: [
                Icon(Icons.inbox_outlined, color: AppTheme.secondaryText),
                SizedBox(width: 12),
                Expanded(child: Text('暂无匹配记录。可以新增投递，或从导入页导入表格。')),
              ],
            ),
          )
        else
          ...records.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ApplicationCard(record: record),
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
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.record});

  final ApplicationRecord record;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed(ApplicationDetailPage.routeName, arguments: record.id);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
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
                    label: statusLabel(record.status),
                    color: AppTheme.primary,
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
                    label: directionLabel(record.jobDirection),
                    color: AppTheme.success,
                  ),
                  if (record.city.isNotEmpty)
                    StatusPill(
                      label: record.city,
                      color: AppTheme.secondaryText,
                    ),
                  if (record.channel.isNotEmpty)
                    StatusPill(
                      label: record.channel,
                      color: AppTheme.secondaryText,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '投递日期 ${record.applyDate.isEmpty ? '未填写' : record.applyDate} · 下次跟进 ${record.nextFollowDate.isEmpty ? '待定' : record.nextFollowDate}',
                style: const TextStyle(color: AppTheme.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
