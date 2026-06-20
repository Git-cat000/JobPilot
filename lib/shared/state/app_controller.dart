import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_strings.dart';
import '../../core/enums/job_enums.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_restore_exception.dart';
import '../../data/models/application_record.dart';
import '../../data/models/app_option.dart';
import '../../data/models/import_log.dart';
import '../../data/models/stage_record.dart';
import '../../data/repositories/application_repository.dart';
import '../../data/repositories/app_option_repository.dart';
import '../../data/repositories/app_settings_repository.dart';
import '../../data/repositories/import_log_repository.dart';
import '../../data/repositories/import_repository.dart';
import '../../data/repositories/stage_repository.dart';
import '../../features/import_export/services/import_parser.dart';
import '../../features/settings/services/export_service.dart';
import '../../features/settings/services/jobpack_validator.dart';
import 'app_controller_contract.dart';

class AppController extends AppControllerContract {
  AppController({
    ApplicationRepository? applicationRepository,
    StageRepository? stageRepository,
    ImportLogRepository? importLogRepository,
    ImportRepository? importRepository,
    AppOptionRepository? appOptionRepository,
    AppSettingsRepository? appSettingsRepository,
    ImportParser? importParser,
    ExportService? exportService,
  }) : applicationRepository = applicationRepository ?? ApplicationRepository(),
       stageRepository = stageRepository ?? StageRepository(),
       importLogRepository = importLogRepository ?? ImportLogRepository(),
       importRepository = importRepository ?? ImportRepository(),
       appOptionRepository = appOptionRepository ?? AppOptionRepository(),
       appSettingsRepository = appSettingsRepository ?? AppSettingsRepository(),
       importParser = importParser ?? ImportParser(),
       exportService = exportService ?? ExportService();

  final ApplicationRepository applicationRepository;
  final StageRepository stageRepository;
  final ImportLogRepository importLogRepository;
  final ImportRepository importRepository;
  final AppOptionRepository appOptionRepository;
  final AppSettingsRepository appSettingsRepository;
  final ImportParser importParser;
  final ExportService exportService;

  @override
  var applications = <ApplicationRecord>[];
  var stages = <StageRecord>[];
  @override
  var customStatuses = <String, String>{};
  @override
  var customDirections = <String, String>{};
  @override
  String language = 'zh';
  @override
  ImportPreview? currentPreview;
  @override
  String message = '';
  @override
  bool isBusy = false;
  @override
  String version = '1.2.0+3';

  @override
  bool get isDemo => false;

  @override
  AppStrings get strings => AppStrings(language);

  static const releasesUrl = 'https://github.com/Git-cat000/JobPilot/releases';

  @override
  Future<void> init() async {
    language = await appSettingsRepository.get('language', fallback: 'zh');
    try {
      final info = await PackageInfo.fromPlatform();
      version = _formatPackageVersion(info);
    } catch (_) {
      // 读取包信息失败时保留默认版本号，不影响其余初始化。
    }
    await reload();
  }

  /// 将 [PackageInfo.version] 与 [PackageInfo.buildNumber] 拼接为
  /// "语义化版本+构建号" 格式（如 "1.2.0+3"）。
  /// 如果 [PackageInfo.version] 意外已含 "+"，则以 "+" 左侧部分为准，
  /// 避免重复出现 "+"。
  static String _formatPackageVersion(PackageInfo info) {
    if (info.buildNumber.trim().isEmpty) return info.version;
    final base = info.version.contains('+')
        ? info.version.split('+').first
        : info.version;
    return '$base+${info.buildNumber}';
  }

  /// 仅在用户点击「检查更新」时打开 GitHub Releases 页面；
  /// 不轮询、不调用更新 API、不添加后台网络行为。
  @override
  Future<void> openUpdatesPage() async {
    final uri = Uri.parse(releasesUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      message = strings.openUpdateFailed;
      notifyListeners();
    }
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

  @override
  List<StageRecord> stagesFor(String applicationId) {
    return stages
        .where((stage) => stage.applicationId == applicationId)
        .toList();
  }

  @override
  Future<void> saveApplication(ApplicationRecord record) async {
    await applicationRepository.upsert(record);
    message = strings.savedApplication;
    await reload();
  }

  @override
  Future<void> deleteApplication(String id) async {
    await applicationRepository.delete(id);
    message = strings.deletedApplication;
    await reload();
  }

  @override
  Future<void> deleteApplications(Iterable<String> ids) async {
    await applicationRepository.deleteMany(ids);
    message = strings.deletedApplications(ids.length);
    await reload();
  }

  @override
  Future<String> addCustomStatus(String label) async {
    final value = 'custom_status_${DateTime.now().millisecondsSinceEpoch}';
    await appOptionRepository.add(
      AppOption(type: 'status', value: value, label: label.trim()),
    );
    await reload();
    return value;
  }

  @override
  Future<String> addCustomDirection(String label) async {
    final value = 'custom_direction_${DateTime.now().millisecondsSinceEpoch}';
    await appOptionRepository.add(
      AppOption(type: 'direction', value: value, label: label.trim()),
    );
    await reload();
    return value;
  }

  @override
  Future<void> deleteCustomStatus(String value) async {
    if (!customStatuses.containsKey(value)) {
      return;
    }
    await appOptionRepository.delete(type: 'status', value: value);
    await reload();
  }

  @override
  Future<void> deleteCustomDirection(String value) async {
    if (!customDirections.containsKey(value)) {
      return;
    }
    await appOptionRepository.delete(type: 'direction', value: value);
    await reload();
  }

  @override
  Future<void> setLanguage(String value) async {
    language = value;
    await appSettingsRepository.set('language', value);
    notifyListeners();
  }

  @override
  Map<String, String> statusOptions() => {...statusLabels, ...customStatuses};

  @override
  Map<String, String> directionOptions() => {
    ...directionLabels,
    ...customDirections,
  };

  @override
  Future<void> saveStage(StageRecord stage) async {
    await stageRepository.upsert(stage);
    message = strings.savedStage;
    await reload();
  }

  @override
  Future<void> deleteStage(String id) async {
    await stageRepository.delete(id);
    message = strings.deletedStage;
    await reload();
  }

  @override
  Future<void> clearAll() async {
    await applicationRepository.clearAll();
    message = strings.clearedAll;
    await reload();
  }

  @override
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

  @override
  Future<void> confirmImport() async {
    final preview = currentPreview;
    if (preview == null) {
      return;
    }
    final records = preview.rows
        .where((row) => row.canImport)
        .map((row) => row.record)
        .toList();
    await importRepository.commit(
      records,
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
    message = strings.importedRecords(records.length);
    await reload();
  }

  @override
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

  @override
  Future<File> exportCsv() => exportService.exportCsv(applications);

  @override
  Future<File> exportXlsx() => exportService.exportXlsx(applications);

  @override
  Future<File> exportJobpack() async {
    isBusy = true;
    notifyListeners();
    Directory? snapshotDir;
    try {
      // 导出一致快照，绝不直接归档正在打开的活动数据库。
      final snapshot = await AppDatabase.instance.createSnapshot();
      snapshotDir = snapshot.parent;
      return await exportService.exportJobpack(
        databasePath: snapshot.path,
        applicationCount: applications.length,
        stageCount: stages.length,
        appVersion: version,
      );
    } finally {
      if (snapshotDir != null && snapshotDir.existsSync()) {
        try {
          snapshotDir.deleteSync(recursive: true);
        } catch (_) {
          // 清理临时快照失败不影响导出结果。
        }
      }
      isBusy = false;
      notifyListeners();
    }
  }

  @override
  Future<void> importJobpack() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jobpack'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) {
      // 用户取消选择：清空提示，避免页面误显示上一次的消息。
      message = '';
      notifyListeners();
      return;
    }
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    try {
      await restoreJobpackBytes(bytes);
    } on JobpackValidationException catch (e) {
      // 失败时设置本地化、不含内部路径的提示，便于 Settings 展示后重新抛出。
      message = e.localizedMessage(strings);
      notifyListeners();
      rethrow;
    }
  }

  /// 校验并以原子方式恢复 `.jobpack` 字节数据。
  ///
  /// 校验或恢复失败时抛出 [JobpackValidationException]，活动库保持不变；
  /// 成功时刷新内存状态。临时抽取目录在 `finally` 中清理。
  Future<void> restoreJobpackBytes(List<int> bytes) async {
    const validator = JobpackValidator();
    ValidatedJobpack? extraction;
    try {
      extraction = await validator.validate(bytes);
      try {
        await AppDatabase.instance.replaceWith(extraction.databaseFile);
      } on DatabaseRestoreException {
        // 数据层恢复失败已自动回滚到原库；映射为面向用户的本地化原因。
        throw const JobpackValidationException(
          JobpackValidationReason.restoreFailed,
        );
      }
      message = strings.restoredBackup;
      await reload();
    } finally {
      await extraction?.dispose();
    }
  }
}
