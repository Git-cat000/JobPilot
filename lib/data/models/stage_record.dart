import 'package:uuid/uuid.dart';

class StageRecord {
  StageRecord({
    required this.id,
    required this.applicationId,
    required this.stageType,
    required this.stageTime,
    required this.result,
    required this.questions,
    required this.review,
    required this.nextAction,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StageRecord.create({
    required String applicationId,
    required String stageType,
    String stageTime = '',
    String result = '待反馈',
    String questions = '',
    String review = '',
    String nextAction = '',
  }) {
    final now = DateTime.now().toIso8601String();
    return StageRecord(
      id: const Uuid().v4(),
      applicationId: applicationId,
      stageType: stageType,
      stageTime: stageTime,
      result: result,
      questions: questions,
      review: review,
      nextAction: nextAction,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String applicationId;
  final String stageType;
  final String stageTime;
  final String result;
  final String questions;
  final String review;
  final String nextAction;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'application_id': applicationId,
      'stage_type': stageType,
      'stage_time': stageTime,
      'result': result,
      'questions': questions,
      'review': review,
      'next_action': nextAction,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory StageRecord.fromMap(Map<String, Object?> map) {
    return StageRecord(
      id: map['id'] as String,
      applicationId: map['application_id'] as String? ?? '',
      stageType: map['stage_type'] as String? ?? '其他',
      stageTime: map['stage_time'] as String? ?? '',
      result: map['result'] as String? ?? '待反馈',
      questions: map['questions'] as String? ?? '',
      review: map['review'] as String? ?? '',
      nextAction: map['next_action'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }
}
