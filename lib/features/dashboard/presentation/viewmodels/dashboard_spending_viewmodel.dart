import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/features/analytics/domain/entities/category_breakdown_entity.dart';
import 'package:nyimpeun/features/wallet/domain/repositories/wallet_repository.dart';

class DashboardSpendingState {
  const DashboardSpendingState({
    this.isLoading = false,
    this.errorMessage,
    this.categoryBreakdowns = const [],
    this.availableMonths = const [],
    this.selectedMonth,
    this.selectedWalletId,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<CategoryBreakdownEntity> categoryBreakdowns;
  final List<DateTime> availableMonths;
  final DateTime? selectedMonth;
  final String? selectedWalletId;

  DashboardSpendingState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CategoryBreakdownEntity>? categoryBreakdowns,
    List<DateTime>? availableMonths,
    DateTime? selectedMonth,
    String? selectedWalletId,
    bool clearError = false,
    bool clearWallet = false,
  }) {
    return DashboardSpendingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      categoryBreakdowns: categoryBreakdowns ?? this.categoryBreakdowns,
      availableMonths: availableMonths ?? this.availableMonths,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedWalletId: clearWallet ? null : (selectedWalletId ?? this.selectedWalletId),
    );
  }
}

class DashboardSpendingNotifier extends StateNotifier<DashboardSpendingState> {
  DashboardSpendingNotifier({required WalletRepository repository})
      : _repository = repository,
        super(const DashboardSpendingState());

  final WalletRepository _repository;

  Future<void> load(String userId, {String? walletId}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      selectedWalletId: walletId,
      clearWallet: walletId == null,
    );
    try {
      final now = DateTime.now();
      
      // We check the last 6 months to see which have expenses
      final monthsToCheck = _lastSixMonths(now);
      final futures = <Future>[];
      for (final month in monthsToCheck) {
        futures.add(
          _repository.getTransactions(
            userId: userId,
            walletId: state.selectedWalletId,
            startDate: DateTime(month.year, month.month, 1),
            endDate: DateTime(month.year, month.month + 1, 1),
            limit: 500,
          ),
        );
      }
      
      // Also get categories
      futures.add(_repository.getCategories(userId));
      
      final results = await Future.wait(futures);
      final categories = results.last as dynamic;
      
      final validMonths = <DateTime>[];
      
      for (int i = 0; i < monthsToCheck.length; i++) {
        final transactions = results[i] as dynamic;
        bool hasExpense = false;
        for (final tx in transactions) {
          if (tx.isExpense) {
            hasExpense = true;
            break;
          }
        }
        if (hasExpense) {
          validMonths.add(monthsToCheck[i]);
        }
      }
      
      final targetMonth = state.selectedMonth ?? (validMonths.isNotEmpty ? validMonths.first : DateTime(now.year, now.month));
      
      // Find the transactions for the target month from the results we just fetched
      int targetIndex = monthsToCheck.indexWhere((m) => m.year == targetMonth.year && m.month == targetMonth.month);
      
      List<CategoryBreakdownEntity> breakdowns = [];
      
      if (targetIndex != -1) {
        final transactions = results[targetIndex] as dynamic;
        breakdowns = _calculateBreakdown(transactions, categories);
      }
      
      state = state.copyWith(
        isLoading: false,
        availableMonths: validMonths,
        selectedMonth: targetMonth,
        categoryBreakdowns: breakdowns,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> changeMonth(String userId, DateTime month) async {
    state = state.copyWith(selectedMonth: month, isLoading: true, clearError: true);
    try {
      final futures = await Future.wait([
        _repository.getTransactions(
          userId: userId,
          walletId: state.selectedWalletId,
          startDate: DateTime(month.year, month.month, 1),
          endDate: DateTime(month.year, month.month + 1, 1),
          limit: 500,
        ),
        _repository.getCategories(userId),
      ]);
      
      final transactions = futures[0] as dynamic;
      final categories = futures[1] as dynamic;
      
      final breakdowns = _calculateBreakdown(transactions, categories);
      
      state = state.copyWith(
        isLoading: false,
        categoryBreakdowns: breakdowns,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  List<CategoryBreakdownEntity> _calculateBreakdown(dynamic transactions, dynamic categories) {
    int totalExpense = 0;
    final Map<String, int> categoryTotals = {};
    final Map<String, int> categoryCounts = {};

    for (final tx in transactions) {
      if (tx.isExpense) {
        totalExpense += tx.amount as int;
        final catId = tx.categoryId ?? 'uncategorized';
        categoryTotals[catId] = (categoryTotals[catId] ?? 0) + (tx.amount as int);
        categoryCounts[catId] = (categoryCounts[catId] ?? 0) + 1;
      }
    }

    final breakdowns = <CategoryBreakdownEntity>[];
    if (totalExpense > 0) {
      categoryTotals.forEach((catId, amount) {
        final catIndex = categories.indexWhere((c) => c.id == catId);
        final cat = catIndex >= 0 ? categories[catIndex] : null;

        breakdowns.add(CategoryBreakdownEntity(
          categoryId: catId,
          categoryName: cat?.name ?? 'Unknown',
          categoryIcon: cat?.icon ?? 'help',
          categoryColor: cat?.color ?? '#9E9E9E',
          totalAmount: amount,
          percentage: amount / totalExpense,
          transactionCount: categoryCounts[catId] ?? 0,
        ));
      });
    }
    return breakdowns;
  }

  List<DateTime> _lastSixMonths(DateTime now) {
    return List.generate(6, (index) {
      int y = now.year;
      int m = now.month - index;
      while (m <= 0) {
        m += 12;
        y -= 1;
      }
      return DateTime(y, m);
    });
  }
}
