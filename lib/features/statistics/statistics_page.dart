import 'package:flutter/material.dart';

import '../../core/enums/job_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/widgets/adaptive.dart';
import '../../shared/widgets/app_card.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdaptiveTabHeader(title: '统计'),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('按状态统计'),
              const SizedBox(height: 12),
              ...statusLabels.entries.map(
                (entry) => _StatRow(
                  label: entry.value,
                  value:
                      '${controller.applications.where((item) => item.status == entry.key).length}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('按岗位方向统计'),
              const SizedBox(height: 12),
              ...directionLabels.entries.map(
                (entry) => _StatRow(
                  label: entry.value,
                  value:
                      '${controller.applications.where((item) => item.jobDirection == entry.key).length}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('按投递渠道统计'),
              const SizedBox(height: 12),
              ..._channelCounts(controller).entries.map(
                (entry) => _StatRow(label: entry.key, value: '${entry.value}'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, int> _channelCounts(AppController controller) {
    final counts = <String, int>{};
    for (final item in controller.applications) {
      final key = item.channel.isEmpty ? '未填写' : item.channel;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts.isEmpty ? {'暂无数据': 0} : counts;
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
