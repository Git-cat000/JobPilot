const statusLabels = {
  'not_applied': '未投递',
  'applied': '已投递',
  'resume_screen': '简历筛选',
  'written_test': '笔试',
  'first_interview': '一面',
  'second_interview': '二面',
  'final_interview': '终面',
  'hr_interview': 'HR 面',
  'offer_negotiation': '谈薪',
  'offer': 'Offer',
  'signed': '已签约',
  'rejected': '拒绝',
  'abandoned': '放弃',
  'paused': '暂停',
};

const statusLabelsEn = {
  'not_applied': 'Not applied',
  'applied': 'Applied',
  'resume_screen': 'Resume screen',
  'written_test': 'Written test',
  'first_interview': 'First interview',
  'second_interview': 'Second interview',
  'final_interview': 'Final interview',
  'hr_interview': 'HR interview',
  'offer_negotiation': 'Negotiation',
  'offer': 'Offer',
  'signed': 'Signed',
  'rejected': 'Rejected',
  'abandoned': 'Abandoned',
  'paused': 'Paused',
};

const directionLabels = {
  'semiconductor': '半导体',
  'ai_algorithm': 'AI / 算法',
  'quant': '量化',
  'internet_dev': '互联网开发',
  'embedded': '嵌入式',
  'data_analysis': '数据分析',
  'product': '产品',
  'operations': '运营',
  'finance': '金融',
  'consulting': '咨询',
  'research': '科研',
  'other': '其他',
};

const directionLabelsEn = {
  'semiconductor': 'Semiconductor',
  'ai_algorithm': 'AI / Algorithm',
  'quant': 'Quant',
  'internet_dev': 'Internet dev',
  'embedded': 'Embedded',
  'data_analysis': 'Data analysis',
  'product': 'Product',
  'operations': 'Operations',
  'finance': 'Finance',
  'consulting': 'Consulting',
  'research': 'Research',
  'other': 'Other',
};

const priorityLabels = {'S': '最高优先级', 'A': '高优先级', 'B': '普通', 'C': '低优先级'};
const priorityLabelsEn = {
  'S': 'Critical',
  'A': 'High',
  'B': 'Normal',
  'C': 'Low',
};

const stageTypeLabels = ['笔试', '一面', '二面', 'HR 面', '电话沟通', '其他'];
const stageResultLabels = ['待反馈', '通过', '未通过', '取消', '其他'];

String statusLabel(
  String value, {
  String language = 'zh',
  Map<String, String> custom = const {},
}) {
  return custom[value] ??
      (language == 'en' ? statusLabelsEn[value] : statusLabels[value]) ??
      value;
}

String directionLabel(
  String value, {
  String language = 'zh',
  Map<String, String> custom = const {},
}) {
  return custom[value] ??
      (language == 'en' ? directionLabelsEn[value] : directionLabels[value]) ??
      value;
}

String priorityLabel(String value, {String language = 'zh'}) {
  return (language == 'en' ? priorityLabelsEn[value] : priorityLabels[value]) ??
      value;
}

String? directionValueFromLabel(String label) {
  final normalized = label.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  for (final entry in {...directionLabels, ...directionLabelsEn}.entries) {
    if (entry.value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '') ==
        normalized) {
      return entry.key;
    }
  }
  return null;
}
