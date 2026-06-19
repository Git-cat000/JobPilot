import 'package:url_launcher/url_launcher.dart';

import '../../core/app_strings.dart';
import '../../core/enums/job_enums.dart';
import '../../data/models/application_record.dart';
import '../../data/models/stage_record.dart';
import '../../features/import_export/services/import_parser.dart';
import 'app_controller_contract.dart';

/// Web 只读演示控制器。
///
/// 用内存中的示例数据驱动与原生端完全相同的 dashboard / 投递 / 详情 / 统计 /
/// 设置页面，便于在浏览器中预览。所有写入、导入、导出、备份操作都是空操作，
/// 仅通过 [message] 给出只读演示提示。不接触 `dart:io`、SQLite 或文件系统。
class DemoAppController extends AppControllerContract {
  @override
  var applications = <ApplicationRecord>[];
  var _stages = <StageRecord>[];
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
  Map<String, String> customStatuses = const {};
  @override
  Map<String, String> customDirections = const {};

  @override
  bool get isDemo => true;

  @override
  AppStrings get strings => AppStrings(language);

  static const _releasesUrl = 'https://github.com/Git-cat000/JobPilot/releases';

  @override
  Future<void> init() async {
    _seed();
    notifyListeners();
  }

  void _seed() {
    final now = DateTime.now();
    String date(int daysAgo) => now
        .subtract(Duration(days: daysAgo))
        .toIso8601String()
        .split('T')
        .first;

    applications = [
      ApplicationRecord.create(
        companyName: '字节跳动',
        jobTitle: 'Flutter 开发工程师',
        jobDirection: 'internet_dev',
        city: '北京',
        channel: '内推',
        status: 'second_interview',
        priority: 'A',
        applyDate: date(12),
        nextFollowDate: date(-2),
      ),
      ApplicationRecord.create(
        companyName: '腾讯',
        jobTitle: '前端工程师',
        jobDirection: 'internet_dev',
        city: '深圳',
        channel: '官网',
        status: 'written_test',
        priority: 'B',
        applyDate: date(8),
      ),
      ApplicationRecord.create(
        companyName: '阿里巴巴',
        jobTitle: '后端开发（Java）',
        jobDirection: 'internet_dev',
        city: '杭州',
        channel: 'BOSS 直聘',
        status: 'offer',
        priority: 'S',
        applyDate: date(30),
      ),
      ApplicationRecord.create(
        companyName: '美团',
        jobTitle: '数据分析实习生',
        jobDirection: 'data_analysis',
        city: '北京',
        channel: '校招',
        status: 'rejected',
        priority: 'B',
        applyDate: date(20),
      ),
      ApplicationRecord.create(
        companyName: '网易',
        jobTitle: '产品经理',
        jobDirection: 'product',
        city: '广州',
        channel: '猎头',
        status: 'process_terminated',
        priority: 'C',
        applyDate: date(25),
      ),
      ApplicationRecord.create(
        companyName: '小米',
        jobTitle: 'Android 开发工程师',
        jobDirection: 'internet_dev',
        city: '北京',
        channel: '内推',
        status: 'applied',
        priority: 'B',
        applyDate: date(3),
        nextFollowDate: date(-3),
      ),
    ];

    _stages = [
      StageRecord.create(
        applicationId: applications[0].id,
        stageType: '一面',
        stageTime: date(5),
        result: '通过',
        questions: 'Flutter 渲染机制、State 生命周期',
        review: '表达清晰，算法题需加强',
        nextAction: '准备二面系统设计',
      ),
      StageRecord.create(
        applicationId: applications[0].id,
        stageType: '二面',
        stageTime: date(1),
        result: '待反馈',
        nextAction: '等待结果',
      ),
      StageRecord.create(
        applicationId: applications[2].id,
        stageType: 'HR 面',
        stageTime: date(10),
        result: '通过',
        nextAction: '谈薪',
      ),
    ];
  }

  @override
  List<StageRecord> stagesFor(String applicationId) =>
      _stages.where((s) => s.applicationId == applicationId).toList();

  @override
  Map<String, String> statusOptions() => statusLabels;

  @override
  Map<String, String> directionOptions() => directionLabels;

  @override
  Future<void> setLanguage(String value) async {
    language = value;
    notifyListeners();
  }

  void _demoNotice() {
    message = strings.demoNotice;
    notifyListeners();
  }

  @override
  Future<void> saveApplication(ApplicationRecord record) async => _demoNotice();

  @override
  Future<void> deleteApplication(String id) async => _demoNotice();

  @override
  Future<void> deleteApplications(Iterable<String> ids) async => _demoNotice();

  @override
  Future<String> addCustomStatus(String label) async {
    _demoNotice();
    return '';
  }

  @override
  Future<String> addCustomDirection(String label) async {
    _demoNotice();
    return '';
  }

  @override
  Future<void> deleteCustomStatus(String value) async => _demoNotice();

  @override
  Future<void> deleteCustomDirection(String value) async => _demoNotice();

  @override
  Future<void> saveStage(StageRecord stage) async => _demoNotice();

  @override
  Future<void> deleteStage(String id) async => _demoNotice();

  @override
  Future<void> clearAll() async => _demoNotice();

  @override
  Future<Object> exportCsv() async {
    _demoNotice();
    return '';
  }

  @override
  Future<Object> exportXlsx() async {
    _demoNotice();
    return '';
  }

  @override
  Future<Object> exportJobpack() async {
    _demoNotice();
    return '';
  }

  @override
  Future<ImportPreview?> pickAndPreviewImport() async {
    _demoNotice();
    return null;
  }

  @override
  Future<void> confirmImport() async => _demoNotice();

  @override
  void updatePreviewRecord(int index, ApplicationRecord record) =>
      _demoNotice();

  @override
  Future<void> importJobpack() async => _demoNotice();

  @override
  Future<void> openUpdatesPage() async {
    final uri = Uri.parse(_releasesUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      message = strings.openUpdateFailed;
      notifyListeners();
    }
  }
}
