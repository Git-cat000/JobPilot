class AppStrings {
  const AppStrings(this.localeCode);

  final String localeCode;
  bool get isEn => localeCode == 'en';

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
  String get select => isEn ? 'Select' : '多选';
  String get done => isEn ? 'Done' : '完成';
  String get searchHint =>
      isEn ? 'Search company, title, or city' : '搜索公司、岗位或城市';
  String get allStatus => isEn ? 'All status' : '全部状态';
  String get allDirection => isEn ? 'All directions' : '全部方向';
  String get recentApplications => isEn ? 'Recent applications' : '最近投递';
  String get followUp => isEn ? 'Follow-up' : '本周提醒';
  String get jobRecords => isEn ? 'Applications' : '投递记录';
  String get importPreview => isEn ? 'Import preview' : '导入预览';
  String get chooseFilePreview => isEn ? 'Choose file and preview' : '选择文件并预览';
  String get languageSetting => isEn ? 'Language' : '语言';
  String get chinese => isEn ? 'Chinese' : '中文';
  String get english => isEn ? 'English' : '英文';
  String get noMatch =>
      isEn ? 'No matching records.' : '暂无匹配记录。可以新增投递，或从导入页导入表格。';
}
