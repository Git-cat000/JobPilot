class ClassificationService {
  ClassificationService({
    Map<String, List<String>>? statusRules,
    Map<String, List<String>>? directionRules,
  }) : statusRules = statusRules ?? defaultStatusRules,
       directionRules = directionRules ?? defaultDirectionRules;

  final Map<String, List<String>> statusRules;
  final Map<String, List<String>> directionRules;

  static const defaultStatusRules = {
    'written_test': ['笔试', '测评', '在线测试', '机试', '性格测试'],
    'first_interview': ['一面', '初面', '技术一面', '第一轮'],
    'second_interview': ['二面', '复面', '主管面', '第二轮'],
    'hr_interview': ['HR', 'hr', '谈薪', '薪资', '人事'],
    'offer': ['offer', 'Offer', '录用', '意向书', '通过'],
    'rejected': ['拒', '挂', '不合适', '感谢关注', '未通过'],
    'applied': ['已投', '投递完成', '等待反馈', '简历筛选'],
    'abandoned': ['放弃', '不投', '取消', '终止'],
  };

  static const defaultDirectionRules = {
    'semiconductor': [
      '半导体',
      '工艺',
      '器件',
      '良率',
      'EDA',
      'TCAD',
      'CST',
      'VNA',
      '存储器',
      'DRAM',
      'NAND',
      'HZO',
      '芯片',
    ],
    'ai_algorithm': [
      '算法',
      '机器学习',
      '深度学习',
      '推荐',
      'NLP',
      'CV',
      'LLM',
      'RAG',
      'Agent',
      '大模型',
    ],
    'quant': ['量化', '策略', '因子', '回测', 'alpha', 'Alpha', '交易', '金融工程'],
    'internet_dev': [
      '后端',
      '前端',
      '客户端',
      '服务端',
      '数据库',
      '分布式',
      'Java',
      'Go',
      'Python',
    ],
  };

  String detectStatus(String text) {
    final source = text.trim();
    if (source.isEmpty) {
      return 'applied';
    }
    for (final entry in statusRules.entries) {
      if (entry.value.any(source.contains)) {
        return entry.key;
      }
    }
    return 'applied';
  }

  String detectDirection(String text) {
    final source = text.trim();
    if (source.isEmpty) {
      return 'other';
    }

    var bestKey = 'other';
    var bestHits = 0;
    for (final entry in directionRules.entries) {
      final hits = entry.value.where(source.contains).length;
      if (hits > bestHits) {
        bestHits = hits;
        bestKey = entry.key;
      }
    }
    return bestKey;
  }
}
