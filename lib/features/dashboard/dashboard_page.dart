import 'package:flutter/material.dart';

import '../../core/enums/job_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/widgets/app_card.dart';
import '../applications/application_detail_page.dart';
import '../applications/application_edit_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final total = controller.applications.length;
    final active = controller.applications
        .where(
          (item) => !['offer', 'rejected', 'abandoned'].contains(item.status),
        )
        .length;
    final interviewing = controller.applications
        .where(
          (item) => [
            'written_test',
            'first_interview',
            'second_interview',
            'hr_interview',
          ].contains(item.status),
        )
        .length;
    final offers = controller.applications
        .where((item) => item.status == 'offer')
        .length;
    final followUps = controller.applications
        .where((item) => item.nextFollowDate.isNotEmpty)
        .take(3)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JobPilot',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.isBusy ? '正在加载本地数据' : '今天适合推进一个小步骤',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(ApplicationEditPage.routeName);
              },
              icon: const Icon(Icons.add),
              label: const Text('新增'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Row(
            children: [
              _StatBlock(label: '总投递', value: '$total'),
              _StatBlock(label: '进行中', value: '$active'),
              _StatBlock(label: '面试中', value: '$interviewing'),
              _StatBlock(label: 'Offer', value: '$offers'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('本周提醒'),
        const SizedBox(height: 10),
        AppCard(
          child: followUps.isEmpty
              ? const Row(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text('暂无待跟进岗位。添加投递后，这里会显示最近需要推进的机会。')),
                  ],
                )
              : Column(
                  children: [
                    for (final item in followUps)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.companyName),
                        subtitle: Text(item.jobTitle),
                        trailing: Text(item.nextFollowDate),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('最近投递'),
        const SizedBox(height: 10),
        if (controller.applications.isEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '还没有投递记录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('先新增一个目标岗位，或从表格导入已有记录。'),
              ],
            ),
          )
        else
          ...controller.applications
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          ApplicationDetailPage.routeName,
                          arguments: item.id,
                        );
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.companyName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(item.jobTitle),
                              ],
                            ),
                          ),
                          StatusPill(
                            label: statusLabel(
                              item.status,
                              language: controller.language,
                              custom: controller.customStatuses,
                            ),
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.secondaryText)),
        ],
      ),
    );
  }
}
