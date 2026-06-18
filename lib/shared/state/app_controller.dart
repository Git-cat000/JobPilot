import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../../data/db/app_database.dart';
import '../../data/models/application_record.dart';
import '../../data/models/import_log.dart';
import '../../data/models/stage_record.dart';
import '../../data/repositories/application_repository.dart';
import '../../data/repositories/import_log_repository.dart';
import '../../data/repositories/stage_repository.dart';
import '../../features/import_export/services/import_parser.dart';
import '../../features/settings/services/export_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    ApplicationRepository? applicationRepository,
    StageRepository? stageRepository,
    ImportLogRepository? importLogRepository,
    ImportParser? importParser,
    ExportService? exportService,
  }) : applicationRepository = applicationRepository ?? ApplicationRepository(),
       stageRepository = stageRepository ?? StageRepository(),
       importLogRepository = importLogRepository ?? ImportLogRepository(),
       importParser = importParser ?? ImportParser(),
       exportService = exportService ?? ExportService();

  final ApplicationRepository applicationRepository;
  final StageRepository stageRepository;
  final ImportLogRepository importLogRepository;
  final ImportParser importParser;
  final ExportService exportService;

  var applications = <ApplicationRecord>[];
  var stages = <StageRecord>[];
  ImportPreview? currentPreview;
  String message = '';
  bool isBusy = false;

  Future<void> init() => reload();

  Future<void> reload() async {
    isBusy = true;
    notifyListeners();
    applications = await applicationRepository.list();
    stages = await stageRepository.listAll();
    isBusy = false;
    notifyListeners();
  }

  List<StageRecord> stagesFor(String applicationId) {
    return stages
        .where((stage) => stage.applicationId == applicationId)
        .toList();
  }

  Future<void> saveApplication(ApplicationRecord record) async {
    await applicationRepository.upsert(record);
    message = '已保存投递记录';
    await reload();
  }

  Future<void> deleteApplication(String id) async {
    await applicationRepository.delete(id);
    message = '已删除投递记录';
    await reload();
  }

  Future<void> saveStage(StageRecord stage) async {
    await stageRepository.upsert(stage);
    message = '已保存流程记录';
    await reload();
  }

  Future<void> deleteStage(String id) async {
    await stageRepository.delete(id);
    message = '已删除流程记录';
    await reload();
  }

  Future<void> clearAll() async {
    await applicationRepository.clearAll();
    message = '已清空本地数据';
    await reload();
  }

  Future<ImportPreview?> pickAndPreviewImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) {
      return null;
    }
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final extension = p.extension(file.name).toLowerCase();
    currentPreview = extension == '.xlsx'
        ? await importParser.parseXlsxBytes(
            bytes,
            fileName: file.name,
            existing: applications,
          )
        : await importParser.parseCsvBytes(
            bytes,
            fileName: file.name,
            existing: applications,
          );
    notifyListeners();
    return currentPreview;
  }

  Future<void> confirmImport() async {
    final preview = currentPreview;
    if (preview == null) {
      return;
    }
    final records = preview.rows
        .where((row) => row.canImport)
        .map((row) => row.record)
        .toList();
    await applicationRepository.insertAll(records);
    await importLogRepository.insert(
      ImportLog.create(
        fileName: preview.fileName,
        totalRows: preview.totalRows,
        successRows: records.length,
        duplicateRows: preview.duplicateRows,
        failedRows: preview.failedRows,
        mappingJson: jsonEncode(preview.mapping),
      ),
    );
    currentPreview = null;
    message = '已导入 ${records.length} 条记录';
    await reload();
  }

  Future<File> exportCsv() => exportService.exportCsv(applications);

  Future<File> exportXlsx() => exportService.exportXlsx(applications);

  Future<File> exportJobpack() async {
    final databasePath = await AppDatabase.instance.databasePath;
    return exportService.exportJobpack(
      databasePath: databasePath,
      applicationCount: applications.length,
      stageCount: stages.length,
    );
  }

  Future<void> importJobpack() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jobpack'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) {
      return;
    }
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final sqlite = archive.files.where((item) => item.name == 'data.sqlite');
    if (sqlite.isEmpty) {
      throw StateError('备份包缺少 data.sqlite');
    }
    final temp = await Directory.systemTemp.createTemp('jobpilot_restore_');
    final sqliteFile = File(p.join(temp.path, 'data.sqlite'));
    sqliteFile.writeAsBytesSync(sqlite.first.content as List<int>);
    await AppDatabase.instance.replaceWith(sqliteFile);
    message = '已恢复备份';
    await reload();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}
