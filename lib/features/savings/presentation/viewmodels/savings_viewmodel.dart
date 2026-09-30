import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/features/savings/domain/entities/savings_contribution_entity.dart';
import 'package:nyimpeun/features/savings/domain/entities/savings_goal_entity.dart';
import 'package:nyimpeun/features/savings/domain/repositories/savings_repository.dart';
import 'package:nyimpeun/features/wallet/domain/entities/transaction_entity.dart';
import 'package:nyimpeun/features/wallet/domain/repositories/wallet_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class SavingsState {
  const SavingsState({
    this.goals = const [],
    this.contributions = const [],
    this.isLoading = false,
    this.isContribLoading = false,
    this.errorMessage,
    this.milestoneReached,
    this.pendingAllocations = const [],
  });

  final List<SavingsGoalEntity> goals;
  final List<SavingsContributionEntity> contributions;
  final bool isLoading;
  final bool isContribLoading;
  final String? errorMessage;
  final String? milestoneReached;
  /// Goals yang memiliki auto-alokasi aktif, diisi saat income masuk
  final List<SavingsAllocationRecommendation> pendingAllocations;

  int get totalTarget => goals.fold(0, (s, g) => s + g.targetAmount);
  int get totalSaved => goals.fold(0, (s, g) => s + g.currentAmount);
  double get overallProgress =>
      totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

  List<SavingsGoalEntity> get activeGoals =>
      goals.where((g) => g.status == 'active' && !g.isCompleted).toList();
  List<SavingsGoalEntity> get completedGoals =>
      goals.where((g) => g.isCompleted).toList();
  List<SavingsGoalEntity> get pausedGoals =>
      goals.where((g) => g.isPaused).toList();

  SavingsState copyWith({
    List<SavingsGoalEntity>? goals,
    List<SavingsContributionEntity>? contributions,
    bool? isLoading,
    bool? isContribLoading,
    String? errorMessage,
    bool clearError = false,
    String? milestoneReached,
    bool clearMilestone = false,
    List<SavingsAllocationRecommendation>? pendingAllocations,
    bool clearPendingAllocations = false,
  }) {
    return SavingsState(
      goals: goals ?? this.goals,
      contributions: contributions ?? this.contributions,
      isLoading: isLoading ?? this.isLoading,
      isContribLoading: isContribLoading ?? this.isContribLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      milestoneReached:
          clearMilestone ? null : (milestoneReached ?? this.milestoneReached),
      pendingAllocations: clearPendingAllocations
          ? []
          : (pendingAllocations ?? this.pendingAllocations),
    );
  }
}

/// Mewakili 1 rekomendasi alokasi dari sebuah goal
class SavingsAllocationRecommendation {
  const SavingsAllocationRecommendation({
    required this.goal,
    required this.recommendedAmount,
  });
  final SavingsGoalEntity goal;
  final int recommendedAmount;
}

// Backwards-compat alias used in add_transaction_page
typedef SavingsPendingAllocation = SavingsAllocationRecommendation;

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SavingsNotifier extends StateNotifier<SavingsState> {
  SavingsNotifier({
    required SavingsRepository repository,
    required WalletRepository walletRepository,
  })  : _repository = repository,
        _walletRepository = walletRepository,
        super(const SavingsState());

  final SavingsRepository _repository;
  final WalletRepository _walletRepository;

  Future<void> loadGoals(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final goals = await _repository.getGoals(userId);
      state = state.copyWith(goals: goals, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createGoal(SavingsGoalEntity goal) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _repository.createGoal(goal);
      state = state.copyWith(
        goals: [created, ...state.goals],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateGoal(SavingsGoalEntity goal) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateGoal(goal);
      state = state.copyWith(
        goals:
            state.goals.map((g) => g.id == updated.id ? updated : g).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    final prev = state.goals;
    state = state.copyWith(
        goals: prev.where((g) => g.id != goalId).toList());
    try {
      await _repository.deleteGoal(goalId);
    } catch (e) {
      state = state.copyWith(goals: prev, errorMessage: e.toString());
    }
  }

  /// Nabung ke goal: mencatat 2 transaksi transfer (keluar dari source, masuk
  /// ke linked wallet) + contribution record + update current_amount.
  Future<bool> contribute({
    required SavingsGoalEntity goal,
    required String userId,
    required int amount,
    String? note,
    required String sourceWalletId,
    required String sourceWalletName,
  }) async {
    state = state.copyWith(isContribLoading: true, clearError: true);
    try {
      final now = DateTime.now();
      final transferNote =
          note ?? 'Transfer tabungan: ${goal.name}';

      // 1. Transaksi KELUAR dari rekening sumber (expense/transfer)
      await _walletRepository.createTransaction(
        TransactionEntity(
          id: '',
          userId: userId,
          walletId: sourceWalletId,
          walletName: sourceWalletName,
          type: TransactionType.expense,
          amount: amount,
          note: transferNote,
          date: now,
          categoryName: 'Tabungan',
        ),
      );

      // 2. Transaksi MASUK ke rekening linked wallet (income/transfer)
      if (goal.linkedWalletId != null) {
        await _walletRepository.createTransaction(
          TransactionEntity(
            id: '',
            userId: userId,
            walletId: goal.linkedWalletId,
            walletName: goal.linkedWalletName,
            type: TransactionType.income,
            amount: amount,
            note: transferNote,
            date: now,
            categoryName: 'Tabungan',
          ),
        );
      }

      // 3. Catat contribution record
      final contrib = await _repository.addContribution(
        SavingsContributionEntity(
          id: '',
          goalId: goal.id,
          userId: userId,
          amount: amount,
          note: note,
          type: 'manual',
        ),
      );

      // 4. Update goal current_amount
      final prevAmount = goal.currentAmount;
      final newAmount = prevAmount + amount;
      final newStatus =
          newAmount >= goal.targetAmount ? 'completed' : goal.status;
      final updated = await _repository.updateGoal(
        goal.copyWith(currentAmount: newAmount, status: newStatus),
      );

      // 5. Cek milestone
      String? milestone;
      if (goal.targetAmount > 0) {
        final prevPct = prevAmount / goal.targetAmount;
        final newPct = newAmount / goal.targetAmount;
        for (final pct in [0.25, 0.5, 0.75, 1.0]) {
          if (prevPct < pct && newPct >= pct) {
            milestone = '${(pct * 100).toInt()}%';
            break;
          }
        }
      }

      state = state.copyWith(
        goals: state.goals
            .map((g) => g.id == updated.id ? updated : g)
            .toList(),
        contributions: [contrib, ...state.contributions],
        isContribLoading: false,
        milestoneReached: milestone,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
          isContribLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> loadContributions(String goalId) async {
    state = state.copyWith(isContribLoading: true);
    try {
      final contribs = await _repository.getContributions(goalId);
      state =
          state.copyWith(contributions: contribs, isContribLoading: false);
    } catch (e) {
      state = state.copyWith(isContribLoading: false);
    }
  }

  Future<void> toggleStatus(String goalId, String newStatus) async {
    final goal = state.goals.firstWhere((g) => g.id == goalId);
    await updateGoal(goal.copyWith(status: newStatus));
  }

  /// Dipanggil setelah income masuk — menghasilkan daftar REKOMENDASI alokasi
  /// (bukan auto-execute). UI menampilkan dialog konfirmasi.
  void buildAutoAllocateRecommendations({
    required String userId,
    required int incomeAmount,
  }) {
    final activeGoals = state.goals.where(
      (g) => g.status == 'active' && g.autoAllocatePercent > 0 && !g.isCompleted,
    );

    final allocations = activeGoals.map((g) {
      final recommended = (incomeAmount * g.autoAllocatePercent / 100).round();
      return SavingsAllocationRecommendation(goal: g, recommendedAmount: recommended);
    }).where((a) => a.recommendedAmount > 0).toList();

    state = state.copyWith(pendingAllocations: allocations);
  }

  void clearPendingAllocations() =>
      state = state.copyWith(clearPendingAllocations: true);
  void clearMilestone() => state = state.copyWith(clearMilestone: true);
  void clearError() => state = state.copyWith(clearError: true);
}
