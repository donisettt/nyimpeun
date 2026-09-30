import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/features/wallet/domain/entities/transaction_entity.dart';
import 'package:nyimpeun/features/wallet/domain/repositories/wallet_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class TransactionListState {
  const TransactionListState({
    this.transactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.hasMore = true,
    this.totalIncome = 0,
    this.totalExpense = 0,
  });

  final List<TransactionEntity> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasMore;
  final int totalIncome;
  final int totalExpense;

  int get netBalance => totalIncome - totalExpense;

  TransactionListState copyWith({
    List<TransactionEntity>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool? hasMore,
    int? totalIncome,
    int? totalExpense,
    bool clearError = false,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class TransactionListNotifier extends StateNotifier<TransactionListState> {
  TransactionListNotifier({required this._repository})
      : super(const TransactionListState());

  final WalletRepository _repository;
  static const int _pageSize = 20;

  Future<void> loadTransactions({
    required String userId,
    String? walletId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final transactions = await _repository.getTransactions(
        userId: userId,
        walletId: walletId,
        type: type,
        startDate: startDate,
        endDate: endDate,
        limit: _pageSize,
        offset: 0,
      );

      int income = 0;
      int expense = 0;
      for (final t in transactions) {
        if (t.isIncome) income += t.amount;
        if (t.isExpense) expense += t.amount;
      }

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        hasMore: transactions.length == _pageSize,
        totalIncome: income,
        totalExpense: expense,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMore({
    required String userId,
    String? walletId,
    String? type,
  }) async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final more = await _repository.getTransactions(
        userId: userId,
        walletId: walletId,
        type: type,
        limit: _pageSize,
        offset: state.transactions.length,
      );
      state = state.copyWith(
        transactions: [...state.transactions, ...more],
        isLoadingMore: false,
        hasMore: more.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    try {
      final created = await _repository.createTransaction(transaction);
      // Optimistic: prepend to list
      state = state.copyWith(
        transactions: [created, ...state.transactions],
        totalIncome: created.isIncome
            ? state.totalIncome + created.amount
            : state.totalIncome,
        totalExpense: created.isExpense
            ? state.totalExpense + created.amount
            : state.totalExpense,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final prev = state.transactions;
    final removed = prev.firstWhere((t) => t.id == transactionId);
    state = state.copyWith(
      transactions: prev.where((t) => t.id != transactionId).toList(),
      totalIncome: removed.isIncome
          ? state.totalIncome - removed.amount
          : state.totalIncome,
      totalExpense: removed.isExpense
          ? state.totalExpense - removed.amount
          : state.totalExpense,
    );
    try {
      await _repository.deleteTransaction(transactionId);
    } catch (e) {
      // Rollback
      state = state.copyWith(
        transactions: prev,
        errorMessage: e.toString(),
        totalIncome: removed.isIncome
            ? state.totalIncome + removed.amount
            : state.totalIncome,
        totalExpense: removed.isExpense
            ? state.totalExpense + removed.amount
            : state.totalExpense,
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
