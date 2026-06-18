import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../../core/enums/job_enums.dart';
import '../../data/db/app_database.dart';
import '../../data/models/application_record.dart';
import '../../data/models/app_option.dart';
import '../../data/models/import_log.dart';
import '../../data/models/stage_record.dart';
import '../../data/repositories/application_repository.dart';
import '../../data/repositories/app_option_repository.dart';
import '../../data/repositories/app_settings_repository.dart';
import '../../data/repositories/import_log_repository.dart';
import '../../data/repositories/stage_repository.dart';
import '../../features/import_export/services/import_parser.dart';
import '../../features/settings/services/export_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    ApplicationRepository? applicationRepository,
    StageRepository? stageRepository,
    ImportLogRepository? importLogRepository,
    AppOptionRepository? appOptionRepository,
    AppSettingsRepository? appSettingsRepository,
    ImportParser? importParser,
    ExportService? exportService,
  }) : applicationRepository = applicationRepository ?? ApplicationRepository(),
       stageRepository = stageRepository ?? StageRepository(),
       importLogRepository = importLogRepository ?? ImportLogRepository(),
       appOptionRepository = appOptionRepository ?? AppOptionRepository(),
       appSettingsRepository = appSettingsRepository ?? AppSettingsRepository(),
       importParser = importParser ?? ImportParser(),
       exportService = exportService ?? ExportService();

  final ApplicationRepository applicationRepository;
  final StageRepository stageRepository;
  final ImportLogRepository importLogRepository;
  final AppOptionRepository appOptionRepository;
  final AppSettingsRepository appSettingsRepository;
  final ImportParser importParser;
  final ExportService exportService;

  var applications = <ApplicationRecord>[];
  var stages = <StageRecord>[];
  var customStatuses = <String, String>{};
  var customDirections = <String, String>{};
  String language = 'zh';
  ImportPreview? currentPreview;
  String message = '';
  bool isBusy = false;

  Future<void> init() async {
    language = await appSettingsRepository.get('language', fallback: 'zh');
    await reload();
  }

  Future<void> reload() async {
    isBusy = true;
    notifyListeners();
    customStatuses = {
      for (final option in await appOptionRepository.list('status'))
        option.value: option.label,
    };
    customDirections = {
      for (final option in await appOptionRepository.list('direction'))
        option.value: option.label,
    };
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

  Future<void> deleteApplications(Iterable<String> ids) async {
    for (final id in ids) {
      await applicationRepository.delete(id);
    }
    message = '已删除 ${ids.length} 条投递记录';
    await reload();
  }

  Future<String> addCustomStatus(String label) async {
    final value = 'custom_status_${DateTime.now().millisecondsSinceEpoch}';
    await appOptionRepository.add(
      AppOption(type: 'status', value: value, label: label.trim()),
    );
    await reload();
    return value;
  }

  Future<String> addCustomDirection(String label) async {
    final value = 'custom_direction_${DateTime.now().millisecondsSinceEpoch}';
    await appOptionRepository.add(
      AppOption(type: 'direction', value: value, label: label.trim()),
    );
    await reload();
    return value;
  }

  Future<void> deleteCustomStatus(String value) async {
    if (!customStatuses.containsKey(value)) {
      return;
    }
    await appOptionRepository.delete(type: 'status', value: value);
    await reload();
  }

  Future<void> deleteCustomDirection(String value) async {
    if (!customDirections.containsKey(value)) {
      return;
    }
    await appOptionRepository.delete(type: 'direction', value: value);
    await reload();
  }

  Future<void> setLanguage(String value) async {
    language = value;
    await appSettingsRepository.set('language', value);
    notifyListeners();
  }

  Map<String, String> statusOptions() => {...statusLabels, ...customStatuses};

  Map<String, String> directionOptions() => {
    ...directionLabels,
    ...customDirections,
  };

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

  void updatePreviewRecord(int index, ApplicationRecord record) {
    final preview = currentPreview;
    if (preview == null || index < 0 || index >= preview.rows.length) {
      return;
    }
    final status = record.hasRequiredFields
        ? ImportRowStatus.importable
        : ImportRowStatus.missingRequired;
    final rows = [...preview.rows];
    rows[index] = ImportPreviewRow(
      record: record,
      status: status,
      message: status.label,
    );
    currentPreview = ImportPreview(
      fileName: preview.fileName,
      mapping: preview.mapping,
      rows: rows,
    );
    notifyListeners();
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
