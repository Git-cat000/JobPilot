import 'package:flutter/material.dart';

import '../../core/enums/job_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/stage_record.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/widgets/app_card.dart';
import 'application_edit_page.dart';

class ApplicationDetailPage extends StatelessWidget {
  const ApplicationDetailPage({super.key});

  static const routeName = '/applications/detail';

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    final args = ModalRoute.of(context)?.settings.arguments;
    final id = args is String ? args : null;
    final record = controller.applications
        .where((item) => item.id == id)
        .firstOrNull;

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('投递详情')),
        body: const Center(child: Text('记录不存在或已删除')),
      );
    }
    final stages = controller.stagesFor(record.id);

    return Scaffold(
      appBar: AppBar(title: const Text('投递详情')),
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
                  '${record.jobTitle} · ${record.city.isEmpty ? '城市未填' : record.city}',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(
                      label: statusLabel(record.status),
                      color: AppTheme.primary,
                    ),
                    StatusPill(
                      label: directionLabel(record.jobDirection),
                      color: AppTheme.success,
                    ),
                    StatusPill(
                      label: '优先级 ${record.priority}',
                      color: AppTheme.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('投递信息'),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('渠道：${record.channel.isEmpty ? '未填写' : record.channel}'),
                const SizedBox(height: 8),
                Text(
                  '投递日期：${record.applyDate.isEmpty ? '未填写' : record.applyDate}',
                ),
                const SizedBox(height: 8),
                Text(
                  '下次跟进：${record.nextFollowDate.isEmpty ? '待定' : record.nextFollowDate}',
                ),
                const SizedBox(height: 8),
                Text('JD 链接：${record.jdLink.isEmpty ? '未填写' : record.jdLink}'),
                const SizedBox(height: 8),
                Text(
                  '简历版本：${record.resumeVersion.isEmpty ? '未填写' : record.resumeVersion}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionTitle(
            '流程记录',
            action: TextButton.icon(
              onPressed: () => _showStageSheet(context, record.id),
              icon: const Icon(Icons.add),
              label: const Text('添加流程'),
            ),
          ),
          const SizedBox(height: 10),
          if (stages.isEmpty)
            const AppCard(child: Text('还没有流程记录。可以添加笔试、面试、HR 沟通和复盘。'))
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
                        if (stage.questions.isNotEmpty) '问题：${stage.questions}',
                        if (stage.review.isNotEmpty) '复盘：${stage.review}',
                        if (stage.nextAction.isNotEmpty)
                          '下一步：${stage.nextAction}',
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
          const SectionTitle('备注'),
          const SizedBox(height: 10),
          AppCard(child: Text(record.remark.isEmpty ? '暂无备注' : record.remark)),
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
                  label: const Text('编辑'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, record.id),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除投递记录？'),
        content: const Text('删除后，该岗位关联的流程记录也会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
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
                Text('添加流程', style: Theme.of(context).textTheme.titleLarge),
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
                  decoration: const InputDecoration(labelText: '流程类型'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: time,
                  decoration: const InputDecoration(labelText: '时间'),
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
                  decoration: const InputDecoration(labelText: '结果'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: questions,
                  decoration: const InputDecoration(labelText: '问题'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: review,
                  decoration: const InputDecoration(labelText: '复盘'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nextAction,
                  decoration: const InputDecoration(labelText: '下一步行动'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await AppScope.watch(context).saveStage(
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
                  child: const Text('保存流程'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
