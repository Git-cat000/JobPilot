import 'package:flutter/widgets.dart';

import '../../core/app_strings.dart';
import '../../data/models/application_record.dart';
import '../../data/models/stage_record.dart';
import '../../features/import_export/services/import_parser.dart';

/// 面向 UI 的控制器契约。
///
/// 把 widget 树与具体平台实现（原生 SQLite / Web 只读演示）解耦：所有页面
/// 只依赖本契约，`AppScope.watch` 也返回本类型。原生实现见 `AppController`，
/// Web 只读演示实现见 `DemoAppController`，二者由 `controller_factory.dart`
/// 通过条件导入选择。本文件不得引入 `dart:io`，否则 Web 编译会失败。
abstract class AppControllerContract extends ChangeNotifier {
  // ---- 状态（只读视图；具体实现用可变字段承载）----
  List<ApplicationRecord> get applications;
  String get language;
  ImportPreview? get currentPreview;
  String get message;
  bool get isBusy;
  String get version;
  Map<String, String> get customStatuses;
  Map<String, String> get customDirections;

  /// 是否为只读演示控制器（Web）。页面据此隐藏/禁用写入、导入导出与备份。
  bool get isDemo;

  AppStrings get strings;

  // ---- 生命周期 ----
  Future<void> init();

  // ---- 查询 ----
  List<StageRecord> stagesFor(String applicationId);
  Map<String, String> statusOptions();
  Map<String, String> directionOptions();

  // ---- 语言 ----
  Future<void> setLanguage(String value);

  // ---- 写入（演示实现为空操作并给出提示）----
  Future<void> saveApplication(ApplicationRecord record);
  Future<void> deleteApplication(String id);
  Future<void> deleteApplications(Iterable<String> ids);
  Future<String> addCustomStatus(String label);
  Future<String> addCustomDirection(String label);
  Future<void> deleteCustomStatus(String value);
  Future<void> deleteCustomDirection(String value);
  Future<void> saveStage(StageRecord stage);
  Future<void> deleteStage(String id);
  Future<void> clearAll();

  // ---- 导入 / 导出 / 备份（演示实现为空操作并给出提示）----
  /// 返回值是导出产物（原生为 `File`）；契约用 `Object` 以避免引入 `dart:io`。
  /// 调用方按需 `as dynamic` 取路径。
  Future<Object> exportCsv();
  Future<Object> exportXlsx();
  Future<Object> exportJobpack();
  Future<ImportPreview?> pickAndPreviewImport();
  Future<void> confirmImport();
  void updatePreviewRecord(int index, ApplicationRecord record);
  Future<void> importJobpack();

  // ---- 更新检查 ----
  Future<void> openUpdatesPage();
}

/// 将控制器暴露给 widget 树。`watch` 返回契约类型，页面只依赖契约。
class AppScope extends InheritedNotifier<AppControllerContract> {
  const AppScope({
    super.key,
    required AppControllerContract controller,
    required super.child,
  }) : super(notifier: controller);

  static AppControllerContract watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}
