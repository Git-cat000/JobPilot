import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/enums/job_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/state/app_controller_contract.dart';
import '../../shared/widgets/adaptive.dart';
import '../../shared/widgets/app_card.dart';
import '../applications/application_detail_page.dart';
import '../applications/application_edit_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final strings = AppStrings(controller.language);
    final total = controller.applications.length;
    final active = controller.applications
        .where((item) => !terminatedStatuses.contains(item.status))
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
        AdaptiveTabHeader(
          title: strings.appTitle,
          subtitle: controller.isBusy ? strings.loadingLocalData : strings.todayTip,
          actions: [
            if (!controller.isDemo)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    ApplicationEditPage.routeName,
                  );
                },
                icon: const Icon(Icons.add),
                label: Text(strings.add),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Row(
            children: [
              _StatBlock(label: strings.totalApplications, value: '$total'),
              _StatBlock(label: strings.active, value: '$active'),
              _StatBlock(label: strings.interviewing, value: '$interviewing'),
              _StatBlock(label: strings.offerCount, value: '$offers'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionTitle(strings.followUp),
        const SizedBox(height: 10),
        AppCard(
          child: followUps.isEmpty
              ? Row(
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(strings.noFollowUp)),
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
        SectionTitle(strings.recentApplications),
        const SizedBox(height: 10),
        if (controller.applications.isEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.noApplicationsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(strings.noApplicationsHint),
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
                            color: statusColor(item.status),
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
