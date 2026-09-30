import 'package:nyimpeun/features/savings/domain/entities/savings_contribution_entity.dart';
import 'package:nyimpeun/features/savings/domain/entities/savings_goal_entity.dart';

abstract class SavingsRepository {
  // ─── Goals ────────────────────────────────────────────────────────────────
  Future<List<SavingsGoalEntity>> getGoals(String userId);
  Future<SavingsGoalEntity> createGoal(SavingsGoalEntity goal);
  Future<SavingsGoalEntity> updateGoal(SavingsGoalEntity goal);
  Future<void> deleteGoal(String goalId);

  // ─── Contributions ────────────────────────────────────────────────────────
  Future<List<SavingsContributionEntity>> getContributions(String goalId);
  Future<SavingsContributionEntity> addContribution(
      SavingsContributionEntity contribution);

  /// Auto-allocate a percentage of income to active goals
  Future<void> runAutoAllocate({
    required String userId,
    required int incomeAmount,
  });
}
