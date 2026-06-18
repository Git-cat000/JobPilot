import 'package:uuid/uuid.dart';

class ApplicationRecord {
  ApplicationRecord({
    required this.id,
    required this.companyName,
    required this.jobTitle,
    required this.jobDirection,
    required this.city,
    required this.channel,
    required this.status,
    required this.priority,
    required this.applyDate,
    required this.nextFollowDate,
    required this.jdLink,
    required this.resumeVersion,
    required this.salaryRange,
    required this.remark,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApplicationRecord.create({
    required String companyName,
    required String jobTitle,
    String jobDirection = 'other',
    String city = '',
    String channel = '',
    String status = 'applied',
    String priority = 'B',
    String applyDate = '',
    String nextFollowDate = '',
    String jdLink = '',
    String resumeVersion = '',
    String salaryRange = '',
    String remark = '',
  }) {
    final now = DateTime.now().toIso8601String();
    return ApplicationRecord(
      id: const Uuid().v4(),
      companyName: companyName.trim(),
      jobTitle: jobTitle.trim(),
      jobDirection: jobDirection,
      city: city.trim(),
      channel: channel.trim(),
      status: status,
      priority: priority,
      applyDate: applyDate.trim(),
      nextFollowDate: nextFollowDate.trim(),
      jdLink: jdLink.trim(),
      resumeVersion: resumeVersion.trim(),
      salaryRange: salaryRange.trim(),
      remark: remark.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String companyName;
  final String jobTitle;
  final String jobDirection;
  final String city;
  final String channel;
  final String status;
  final String priority;
  final String applyDate;
  final String nextFollowDate;
  final String jdLink;
  final String resumeVersion;
  final String salaryRange;
  final String remark;
  final String createdAt;
  final String updatedAt;

  bool get hasRequiredFields =>
      companyName.trim().isNotEmpty && jobTitle.trim().isNotEmpty;

  ApplicationRecord copyWith({
    String? companyName,
    String? jobTitle,
    String? jobDirection,
    String? city,
    String? channel,
    String? status,
    String? priority,
    String? applyDate,
    String? nextFollowDate,
    String? jdLink,
    String? resumeVersion,
    String? salaryRange,
    String? remark,
  }) {
    return ApplicationRecord(
      id: id,
      companyName: companyName ?? this.companyName,
      jobTitle: jobTitle ?? this.jobTitle,
      jobDirection: jobDirection ?? this.jobDirection,
      city: city ?? this.city,
      channel: channel ?? this.channel,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      applyDate: applyDate ?? this.applyDate,
      nextFollowDate: nextFollowDate ?? this.nextFollowDate,
      jdLink: jdLink ?? this.jdLink,
      resumeVersion: resumeVersion ?? this.resumeVersion,
      salaryRange: salaryRange ?? this.salaryRange,
      remark: remark ?? this.remark,
      createdAt: createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'job_title': jobTitle,
      'job_direction': jobDirection,
      'city': city,
      'channel': channel,
      'status': status,
      'priority': priority,
      'apply_date': applyDate,
      'next_follow_date': nextFollowDate,
      'jd_link': jdLink,
      'resume_version': resumeVersion,
      'salary_range': salaryRange,
      'remark': remark,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ApplicationRecord.fromMap(Map<String, Object?> map) {
    return ApplicationRecord(
      id: map['id'] as String,
      companyName: map['company_name'] as String? ?? '',
      jobTitle: map['job_title'] as String? ?? '',
      jobDirection: map['job_direction'] as String? ?? 'other',
      city: map['city'] as String? ?? '',
      channel: map['channel'] as String? ?? '',
      status: map['status'] as String? ?? 'applied',
      priority: map['priority'] as String? ?? 'B',
      applyDate: map['apply_date'] as String? ?? '',
      nextFollowDate: map['next_follow_date'] as String? ?? '',
      jdLink: map['jd_link'] as String? ?? '',
      resumeVersion: map['resume_version'] as String? ?? '',
      salaryRange: map['salary_range'] as String? ?? '',
      remark: map['remark'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }
}
