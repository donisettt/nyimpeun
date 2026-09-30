import 'package:nyimpeun/features/savings/data/datasources/savings_remote_datasource.dart';
import 'package:nyimpeun/features/savings/data/models/savings_contribution_model.dart';
import 'package:nyimpeun/features/savings/data/models/savings_goal_model.dart';
import 'package:nyimpeun/features/savings/domain/entities/savings_contribution_entity.dart';
import 'package:nyimpeun/features/savings/domain/entities/savings_goal_entity.dart';
import 'package:nyimpeun/features/savings/domain/repositories/savings_repository.dart';

class SavingsRepositoryImpl implements SavingsRepository {
  SavingsRepositoryImpl({required SavingsRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final SavingsRemoteDataSource _remote;

  @override
  Future<List<SavingsGoalEntity>> getGoals(String userId) async {
    final models = await _remote.getGoals(userId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<SavingsGoalEntity> createGoal(SavingsGoalEntity goal) async {
    final model = SavingsGoalModel.fromEntity(goal);
    final result = await _remote.createGoal(model);
    return result.toEntity();
  }

  @override
  Future<SavingsGoalEntity> updateGoal(SavingsGoalEntity goal) async {
    final model = SavingsGoalModel.fromEntity(goal);
    final result = await _remote.updateGoal(goal.id, model.toUpdateJson());
    return result.toEntity();
  }

  @override
  Future<void> deleteGoal(String goalId) => _remote.deleteGoal(goalId);

  @override
  Future<List<SavingsContributionEntity>> getContributions(
      String goalId) async {
    final models = await _remote.getContributions(goalId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<SavingsContributionEntity> addContribution(
      SavingsContributionEntity contribution) async {
    final model = SavingsContributionModel.fromEntity(contribution);
    final result = await _remote.addContribution(model);
    return result.toEntity();
  }

  @override
  Future<void> runAutoAllocate({
    required String userId,
    required int incomeAmount,
  }) async {
    // Fetch all active goals with auto-allocate enabled
    final goals = await getGoals(userId);
    final activeGoals = goals.where(
      (g) => g.status == 'active' && g.autoAllocatePercent > 0 && !g.isCompleted,
    );

    for (final goal in activeGoals) {
      final allocAmount = (incomeAmount * goal.autoAllocatePercent / 100).round();
      if (allocAmount <= 0) continue;

      // Add contribution
      await addContribution(SavingsContributionEntity(
        id: '',
        goalId: goal.id,
        userId: userId,
        amount: allocAmount,
        note: 'Auto-alokasi dari pemasukan',
        type: 'auto_allocate',
      ));

      // Update current_amount on the goal
      final newAmount = goal.currentAmount + allocAmount;
      final newStatus = newAmount >= goal.targetAmount ? 'completed' : goal.status;
      await updateGoal(goal.copyWith(
        currentAmount: newAmount,
        status: newStatus,
      ));
    }
  }
}
