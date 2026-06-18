const statusLabels = {
  'not_applied': '未投递',
  'applied': '已投递',
  'written_test': '笔试',
  'first_interview': '一面',
  'second_interview': '二面',
  'hr_interview': 'HR 面',
  'offer': 'Offer',
  'rejected': '拒绝',
  'abandoned': '放弃',
};

const directionLabels = {
  'semiconductor': '半导体',
  'ai_algorithm': 'AI / 算法',
  'quant': '量化',
  'internet_dev': '互联网开发',
  'other': '其他',
};

const priorityLabels = {'S': '最高优先级', 'A': '高优先级', 'B': '普通', 'C': '低优先级'};

const stageTypeLabels = ['笔试', '一面', '二面', 'HR 面', '电话沟通', '其他'];
const stageResultLabels = ['待反馈', '通过', '未通过', '取消', '其他'];

String statusLabel(String value) => statusLabels[value] ?? value;
String directionLabel(String value) => directionLabels[value] ?? value;
String priorityLabel(String value) => priorityLabels[value] ?? value;
