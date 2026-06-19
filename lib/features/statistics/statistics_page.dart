import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/enums/job_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/state/app_controller_contract.dart';
import '../../shared/widgets/adaptive.dart';
import '../../shared/widgets/app_card.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final strings = AppStrings(controller.language);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdaptiveTabHeader(title: strings.statsTitle),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(strings.byStatus),
              const SizedBox(height: 12),
              ...statusLabels.keys.map(
                (key) => _StatRow(
                  label: statusLabel(
                    key,
                    language: controller.language,
                    custom: controller.customStatuses,
                  ),
                  value:
                      '${controller.applications.where((item) => item.status == key).length}',
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
              SectionTitle(strings.byDirection),
              const SizedBox(height: 12),
              ...directionLabels.keys.map(
                (key) => _StatRow(
                  label: directionLabel(
                    key,
                    language: controller.language,
                    custom: controller.customDirections,
                  ),
                  value:
                      '${controller.applications.where((item) => item.jobDirection == key).length}',
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
              SectionTitle(strings.byChannel),
              const SizedBox(height: 12),
              ..._channelCounts(controller, strings).entries.map(
                (entry) => _StatRow(label: entry.key, value: '${entry.value}'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, int> _channelCounts(AppControllerContract controller, AppStrings strings) {
    final counts = <String, int>{};
    for (final item in controller.applications) {
      final key = item.channel.isEmpty ? strings.unfilled : item.channel;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts.isEmpty ? {strings.noData: 0} : counts;
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
