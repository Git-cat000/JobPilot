import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/enums/job_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/stage_record.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/widgets/adaptive.dart';
import '../../shared/widgets/app_card.dart';
import 'application_edit_page.dart';

class ApplicationDetailPage extends StatelessWidget {
  const ApplicationDetailPage({super.key});

  static const routeName = '/applications/detail';

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final strings = AppStrings(controller.language);
    final args = ModalRoute.of(context)?.settings.arguments;
    final id = args is String ? args : null;
    final record = controller.applications
        .where((item) => item.id == id)
        .firstOrNull;

    if (record == null) {
      return AdaptivePageScaffold(
        title: strings.detailTitle,
        body: Center(child: Text(strings.notFound)),
      );
    }
    final stages = controller.stagesFor(record.id);

    return AdaptivePageScaffold(
      title: strings.detailTitle,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.companyName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${record.jobTitle} · ${record.city.isEmpty ? strings.cityMissing : record.city}',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(
                      label: statusLabel(
                        record.status,
                        language: controller.language,
                        custom: controller.customStatuses,
                      ),
                      color: statusColor(record.status),
                    ),
                    StatusPill(
                      label: directionLabel(
                        record.jobDirection,
                        language: controller.language,
                        custom: controller.customDirections,
                      ),
                      color: AppTheme.success,
                    ),
                    StatusPill(
                      label: strings.priorityLabel(record.priority),
                      color: AppTheme.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionTitle(strings.applicationInfo),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${strings.channelLabel}：${record.channel.isEmpty ? strings.notFilled : record.channel}'),
                const SizedBox(height: 8),
                Text(
                  '${strings.applyDateLabel}：${record.applyDate.isEmpty ? strings.notFilled : record.applyDate}',
                ),
                const SizedBox(height: 8),
                Text(
                  '${strings.nextFollowLabel}：${record.nextFollowDate.isEmpty ? strings.pending : record.nextFollowDate}',
                ),
                const SizedBox(height: 8),
                Text('${strings.jdLinkLabel}：${record.jdLink.isEmpty ? strings.notFilled : record.jdLink}'),
                const SizedBox(height: 8),
                Text(
                  '${strings.resumeVersionLabel}：${record.resumeVersion.isEmpty ? strings.notFilled : record.resumeVersion}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionTitle(
            strings.stageRecords,
            action: TextButton.icon(
              onPressed: () => _showStageSheet(context, record.id),
              icon: const Icon(Icons.add),
              label: Text(strings.addStage),
            ),
          ),
          const SizedBox(height: 10),
          if (stages.isEmpty)
            AppCard(child: Text(strings.noStages))
          else
            ...stages.map(
              (stage) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${stage.stageType} · ${stage.result}'),
                    subtitle: Text(
                      [
                        if (stage.stageTime.isNotEmpty) stage.stageTime,
                        if (stage.questions.isNotEmpty)
                          strings.questionsLabel(stage.questions),
                        if (stage.review.isNotEmpty)
                          strings.reviewLabel(stage.review),
                        if (stage.nextAction.isNotEmpty)
                          strings.nextActionLabel(stage.nextAction),
                      ].join('\n'),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => controller.deleteStage(stage.id),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SectionTitle(strings.remarkTitle),
          const SizedBox(height: 10),
          AppCard(child: Text(record.remark.isEmpty ? strings.noRemark : record.remark)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      ApplicationEditPage.routeName,
                      arguments: record.id,
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(strings.edit),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, record.id),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(strings.delete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final controller = AppScope.watch(context);
    final strings = AppStrings(controller.language);
    final ok = await showAdaptiveConfirm(
      context,
      title: strings.deleteTitle,
      content: strings.deleteContent,
      confirmText: strings.delete,
      destructive: true,
    );
    if (ok) {
      await controller.deleteApplication(id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _showStageSheet(
    BuildContext context,
    String applicationId,
  ) async {
    final controller = AppScope.watch(context);
    final strings = AppStrings(controller.language);
    final type = ValueNotifier(stageTypeLabels.first);
    final result = ValueNotifier(stageResultLabels.first);
    final time = TextEditingController();
    final questions = TextEditingController();
    final review = TextEditingController();
    final nextAction = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: ValueListenableBuilder(
          valueListenable: type,
          builder: (context, typeValue, _) => ValueListenableBuilder(
            valueListenable: result,
            builder: (context, resultValue, _) => ListView(
              shrinkWrap: true,
              children: [
                Text(strings.addStage, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: typeValue,
                  items: stageTypeLabels
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      type.value = value ?? stageTypeLabels.first,
                  decoration: InputDecoration(labelText: strings.stageTypeField),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: time,
                  decoration: InputDecoration(labelText: strings.timeField),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: resultValue,
                  items: stageResultLabels
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      result.value = value ?? stageResultLabels.first,
                  decoration: InputDecoration(labelText: strings.resultField),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: questions,
                  decoration: InputDecoration(labelText: strings.questionsField),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: review,
                  decoration: InputDecoration(labelText: strings.reviewField),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nextAction,
                  decoration: InputDecoration(labelText: strings.nextActionField),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await controller.saveStage(
                      StageRecord.create(
                        applicationId: applicationId,
                        stageType: type.value,
                        stageTime: time.text,
                        result: result.value,
                        questions: questions.text,
                        review: review.text,
                        nextAction: nextAction.text,
                      ),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(strings.saveStage),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
