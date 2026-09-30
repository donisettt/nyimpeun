class SavingsContributionEntity {
  const SavingsContributionEntity({
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
  final String type; // 'manual' | 'auto_allocate'
  final DateTime? createdAt;
}
