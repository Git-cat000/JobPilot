import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/state/app_controller.dart';
import '../../shared/widgets/app_card.dart';
import 'import_preview_page.dart';

class ImportPage extends StatelessWidget {
  const ImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.watch(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '导入',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          '先识别表头并预览结果，确认后才会写入数据库。',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.table_chart_outlined, color: AppTheme.primary),
              const SizedBox(height: 12),
              Text(
                '选择 CSV / XLSX 文件',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('支持自动字段映射、状态识别、岗位方向识别和重复检测。'),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  final preview = await controller.pickAndPreviewImport();
                  if (preview != null && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ImportPreviewPage(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('选择文件并预览'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('字段映射规则'),
        const SizedBox(height: 10),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('公司 / 企业 / 单位 -> company_name'),
              SizedBox(height: 8),
              Text('岗位 / 职位名称 -> job_title'),
              SizedBox(height: 8),
              Text('投递状态 / 流程 -> status'),
            ],
          ),
        ),
      ],
    );
  }
}
