import 'enums/job_enums.dart';

class AppStrings {
  const AppStrings(this.localeCode);

  final String localeCode;
  bool get isEn => localeCode == 'en';

  // ---- 导航 / 通用 ----
  String get home => isEn ? 'Home' : '首页';
  String get applications => isEn ? 'Jobs' : '投递';
  String get import => isEn ? 'Import' : '导入';
  String get statistics => isEn ? 'Stats' : '统计';
  String get settings => isEn ? 'Settings' : '设置';
  String get add => isEn ? 'Add' : '新增';
  String get edit => isEn ? 'Edit' : '编辑';
  String get delete => isEn ? 'Delete' : '删除';
  String get cancel => isEn ? 'Cancel' : '取消';
  String get save => isEn ? 'Save' : '保存';
  String get confirm => isEn ? 'Confirm' : '确认';
  String get select => isEn ? 'Select' : '多选';
  String get done => isEn ? 'Done' : '完成';
  String get close => isEn ? 'Close' : '关闭';
  String get searchHint =>
      isEn ? 'Search company, title, or city' : '搜索公司、岗位或城市';
  String get allStatus => isEn ? 'All status' : '全部状态';
  String get allDirection => isEn ? 'All directions' : '全部方向';
  String get resetFilters => isEn ? 'Reset' : '重置';

  // ---- 首页 ----
  String get appTitle => 'JobPilot';
  String get loadingLocalData => isEn ? 'Loading local data…' : '正在加载本地数据';
  String get todayTip =>
      isEn ? 'A small step forward fits today.' : '今天适合推进一个小步骤';
  String get totalApplications => isEn ? 'Total' : '总投递';
  String get active => isEn ? 'Active' : '进行中';
  String get interviewing => isEn ? 'Interviewing' : '面试中';
  String get offerCount => isEn ? 'Offers' : 'Offer';
  String get followUp => isEn ? 'Follow-up' : '本周提醒';
  String get noFollowUp =>
      isEn
          ? 'No follow-ups yet. Add applications and recent ones to push forward will show here.'
          : '暂无待跟进岗位。添加投递后，这里会显示最近需要推进的机会。';
  String get recentApplications => isEn ? 'Recent applications' : '最近投递';
  String get noApplicationsTitle =>
      isEn ? 'No applications yet' : '还没有投递记录';
  String get noApplicationsHint =>
      isEn
          ? 'Add a target role, or import existing records from a spreadsheet.'
          : '先新增一个目标岗位，或从表格导入已有记录。';

  // ---- 投递列表 ----
  String get jobRecords => isEn ? 'Applications' : '投递记录';
  String get noMatch =>
      isEn
          ? 'No matching records.'
          : '暂无匹配记录。可以新增投递，或从导入页导入表格。';
  String selectedCount(int n) => isEn ? '$n selected' : '已选择 $n 项';
  String get selectAll => isEn ? 'Select all' : '全选';
  String get deselectAll => isEn ? 'Deselect all' : '取消全选';
  String get bulkDeleteTitle => isEn ? 'Delete selected?' : '批量删除？';
  String bulkDeleteContent(int n) =>
      isEn
          ? 'This will delete $n application(s) and their stage records.'
          : '将删除 $n 条投递记录及其流程记录。';
  String get applyDateMissing => isEn ? 'No apply date' : '投递日期未填';
  String get toFollowUp => isEn ? 'To follow up' : '待跟进';
  String followUpOn(String date) => isEn ? 'Follow up $date' : '跟进 $date';

  // ---- 详情 ----
  String get detailTitle => isEn ? 'Application detail' : '投递详情';
  String get notFound => isEn ? 'Record not found or deleted' : '记录不存在或已删除';
  String get cityMissing => isEn ? 'City not set' : '城市未填';
  String priorityLabel(String priority) => isEn ? 'Priority $priority' : '优先级 $priority';
  String get applicationInfo => isEn ? 'Application info' : '投递信息';
  String get channelLabel => isEn ? 'Channel' : '渠道';
  String get applyDateLabel => isEn ? 'Apply date' : '投递日期';
  String get nextFollowLabel => isEn ? 'Next follow-up' : '下次跟进';
  String get jdLinkLabel => isEn ? 'JD link' : 'JD 链接';
  String get resumeVersionLabel => isEn ? 'Resume version' : '简历版本';
  String get notFilled => isEn ? 'Not filled' : '未填写';
  String get pending => isEn ? 'TBD' : '待定';
  String get stageRecords => isEn ? 'Stage records' : '流程记录';
  String get addStage => isEn ? 'Add stage' : '添加流程';
  String get noStages =>
      isEn
          ? 'No stage records yet. Add written tests, interviews, HR chats, and reviews.'
          : '还没有流程记录。可以添加笔试、面试、HR 沟通和复盘。';
  String get remarkTitle => isEn ? 'Remark' : '备注';
  String get noRemark => isEn ? 'No remark' : '暂无备注';
  String get deleteTitle => isEn ? 'Delete application?' : '删除投递记录？';
  String get deleteContent =>
      isEn
          ? 'Deleting will also remove the stage records linked to this role.'
          : '删除后，该岗位关联的流程记录也会被删除。';
  String get stageTypeField => isEn ? 'Stage type' : '流程类型';
  String get timeField => isEn ? 'Time' : '时间';
  String get resultField => isEn ? 'Result' : '结果';
  String get questionsField => isEn ? 'Questions' : '问题';
  String get reviewField => isEn ? 'Review' : '复盘';
  String get nextActionField => isEn ? 'Next action' : '下一步行动';
  String get saveStage => isEn ? 'Save stage' : '保存流程';
  String questionsLabel(String text) => isEn ? 'Questions: $text' : '问题：$text';
  String reviewLabel(String text) => isEn ? 'Review: $text' : '复盘：$text';
  String nextActionLabel(String text) =>
      isEn ? 'Next: $text' : '下一步：$text';

  // ---- 导入 ----
  String get importSubtitle =>
      isEn
          ? 'Headers are detected and previewed first; nothing is written until you confirm.'
          : '先识别表头并预览结果，确认后才会写入数据库。';
  String get chooseFileTitle => isEn ? 'Choose a CSV / XLSX file' : '选择 CSV / XLSX 文件';
  String get chooseFilePreview => isEn ? 'Choose file and preview' : '选择文件并预览';
  String get chinese => isEn ? 'Chinese' : '中文';
  String get english => isEn ? 'English' : '英文';
  String get chooseFileHint =>
      isEn
          ? 'Supports automatic field mapping, status detection, direction detection, and duplicate checks.'
          : '支持自动字段映射、状态识别、岗位方向识别和重复检测。';
  String get fieldMappingTitle => isEn ? 'Field mapping rules' : '字段映射规则';
  String get mappingCompany =>
      isEn ? 'Company / Enterprise / Org -> company_name' : '公司 / 企业 / 单位 -> company_name';
  String get mappingTitle =>
      isEn ? 'Title / Position name -> job_title' : '岗位 / 职位名称 -> job_title';
  String get mappingStatus =>
      isEn ? 'Status / Process -> status' : '投递状态 / 流程 -> status';

  // ---- 导入预览 ----
  String get importPreview => isEn ? 'Import preview' : '导入预览';
  String get noPreview => isEn ? 'No import preview' : '暂无导入预览';
  String get totalRows => isEn ? 'Total' : '总行数';
  String get importable => isEn ? 'Importable' : '可导入';
  String get errors => isEn ? 'Errors' : '错误';
  String get mappingResultTitle => isEn ? 'Field mapping result' : '字段映射结果';
  String get recordStatusTitle => isEn ? 'Record status' : '记录状态';
  String get cancelImport => isEn ? 'Cancel import' : '取消导入';
  String get confirmImport => isEn ? 'Confirm import' : '确认导入';
  String get confirmImportTitle => isEn ? 'Confirm import?' : '确认导入？';
  String confirmImportContent(int n) =>
      isEn
          ? '$n record(s) will be written. Suspected duplicates are imported as previewed; please confirm.'
          : '将写入 $n 条记录。疑似重复会按预览结果一并导入，请确认。';
  String get editRowTitle => isEn ? 'Edit import row' : '编辑导入记录';
  String get editRowHint =>
      isEn ? 'Fix recognition errors before importing.' : '确认导入前可以修正识别错误';
  String get requiredSection => isEn ? 'Required' : '必填信息';
  String get classificationSection => isEn ? 'Classification & status' : '分类与状态';
  String get extraSection => isEn ? 'Extra info' : '补充信息';
  String get companyNameField => isEn ? 'Company name *' : '公司名称 *';
  String get jobTitleField => isEn ? 'Job title *' : '岗位名称 *';
  String get currentStatusField => isEn ? 'Current status' : '当前状态';
  String get jobDirectionField => isEn ? 'Job direction' : '岗位方向';
  String get cityField => isEn ? 'City' : '城市';
  String get channelField => isEn ? 'Channel' : '渠道';
  String get remarkField => isEn ? 'Remark' : '备注';

  // ---- 统计 ----
  String get statsTitle => isEn ? 'Statistics' : '统计';
  String get byStatus => isEn ? 'By status' : '按状态统计';
  String get byDirection => isEn ? 'By direction' : '按岗位方向统计';
  String get byChannel => isEn ? 'By channel' : '按投递渠道统计';
  String get unfilled => isEn ? 'Not filled' : '未填写';
  String get noData => isEn ? 'No data' : '暂无数据';

  // ---- 设置 ----
  String get languageSection => isEn ? 'Language' : '语言 / Language';
  String get exportCsv => isEn ? 'Export CSV' : '导出 CSV';
  String get exportXlsx => isEn ? 'Export XLSX' : '导出 XLSX';
  String get exportJobpack => isEn ? 'Export .jobpack' : '导出 .jobpack';
  String get importJobpack => isEn ? 'Import .jobpack' : '导入 .jobpack';
  String get localData => isEn ? 'Local data' : '本地数据';
  String get localDataDesc =>
      isEn
          ? 'Data is stored in on-device SQLite by default. Clearing and restore both ask for confirmation.'
          : '数据默认保存在本机 SQLite。清空数据和备份恢复都会二次确认。';
  String get clearAll => isEn ? 'Clear all data' : '清空所有数据';
  String get clearAllTitle => isEn ? 'Clear all data?' : '清空所有数据？';
  String get clearAllContent =>
      isEn
          ? 'This deletes all application and stage records and cannot be undone.'
          : '此操作会删除所有投递记录和流程记录，且不可撤销。';
  String get clearAction => isEn ? 'Clear' : '清空';
  String get restoreTitle => isEn ? 'Import backup?' : '导入备份？';
  String get restoreContent =>
      isEn
          ? 'Importing a .jobpack may overwrite current local data. A backup of the original database is kept if restore fails.'
          : '导入 .jobpack 可能覆盖当前本地数据。恢复失败时会保留原数据库备份。';
  String get restoreAction => isEn ? 'Choose backup' : '选择备份';
  String get checkUpdate => isEn ? 'Check for updates' : '检查更新';
  String versionText(String version) =>
      isEn ? 'JobPilot $version · Offline first' : 'JobPilot $version · 离线优先';
  String exportedTo(String path) => isEn ? 'Exported to: $path' : '已导出到：$path';

  // ---- demo 提示 ----
  String get demoNotice =>
      isEn
          ? 'Read-only Web demo. Editing, import, export, and backup are disabled.'
          : '只读 Web 演示：编辑、导入、导出与备份已禁用。';

  // ---- 控制器消息 ----
  String get savedApplication => isEn ? 'Application saved' : '已保存投递记录';
  String get deletedApplication => isEn ? 'Application deleted' : '已删除投递记录';
  String deletedApplications(int n) =>
      isEn ? 'Deleted $n application(s)' : '已删除 $n 条投递记录';
  String get savedStage => isEn ? 'Stage saved' : '已保存流程记录';
  String get deletedStage => isEn ? 'Stage deleted' : '已删除流程记录';
  String get clearedAll => isEn ? 'Local data cleared' : '已清空本地数据';
  String importedRecords(int n) =>
      isEn ? 'Imported $n record(s)' : '已导入 $n 条记录';
  String get restoredBackup => isEn ? 'Backup restored' : '已恢复备份';
  String get exportFailed => isEn ? 'Export failed' : '导出失败';
  String get openUpdateFailed =>
      isEn ? 'Unable to open the updates page.' : '无法打开更新页面。';

  // ---- 流程类型与结果 ----
  String stageTypeLabel(String value) =>
      isEn ? (stageTypeLabelsEn[value] ?? value) : value;
  String stageResultLabel(String value) =>
      isEn ? (stageResultLabelsEn[value] ?? value) : value;

  // ---- 导入行状态 ----
  String importRowStatusLabel(String key) => switch (key) {
    'importable' => isEn ? 'Importable' : '可导入',
    'missingRequired' => isEn ? 'Missing required fields' : '缺少必填字段',
    'suspectedDuplicate' => isEn ? 'Suspected duplicate' : '疑似重复',
    'possibleDuplicate' => isEn ? 'Possible duplicate' : '可能重复',
    'invalidField' => isEn ? 'Invalid field' : '字段异常',
    _ => key,
  };
}
