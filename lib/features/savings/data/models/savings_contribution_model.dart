import 'package:nyimpeun/features/savings/domain/entities/savings_contribution_entity.dart';

class SavingsContributionModel {
  const SavingsContributionModel({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.amount,
    this.note,
    this.type = 'manual',
    this.createdAt,
  });

  final String id;
  final String goalId;
  final String userId;
  final int amount;
  final String? note;
  final String type;
  final DateTime? createdAt;

  factory SavingsContributionModel.fromJson(Map<String, dynamic> json) {
    return SavingsContributionModel(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
      type: json['type'] as String? ?? 'manual',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'goal_id': goalId,
        'user_id': userId,
        'amount': amount,
        'note': note,
        'type': type,
      };

  SavingsContributionEntity toEntity() => SavingsContributionEntity(
        id: id,
        goalId: goalId,
        userId: userId,
        amount: amount,
        note: note,
        type: type,
        createdAt: createdAt,
      );

  static SavingsContributionModel fromEntity(SavingsContributionEntity e) =>
      SavingsContributionModel(
        id: e.id,
        goalId: e.goalId,
        userId: e.userId,
        amount: e.amount,
        note: e.note,
        type: e.type,
        createdAt: e.createdAt,
      );
}
