import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/features/analytics/domain/entities/category_breakdown_entity.dart';
import 'package:nyimpeun/features/analytics/domain/entities/monthly_summary_entity.dart';
import 'package:nyimpeun/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class AnalyticsState {
  const AnalyticsState({
    this.isLoading = false,
    this.errorMessage,
    this.monthlySummaries = const [],
    this.categoryBreakdowns = const [],
    this.wallets = const [],
    this.selectedMonth,
    this.selectedWalletId,
    this.totalBalance = 0,
    this.currentMonthIncome = 0,
    this.currentMonthExpense = 0,
    this.prevMonthIncome = 0,
    this.prevMonthExpense = 0,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<MonthlySummaryEntity> monthlySummaries;
  final List<CategoryBreakdownEntity> categoryBreakdowns;
  final List<WalletEntity> wallets;
  final DateTime? selectedMonth;
  final String? selectedWalletId;
  final int totalBalance;
  final int currentMonthIncome;
  final int currentMonthExpense;
  final int prevMonthIncome;
  final int prevMonthExpense;

  // Derived
  int get currentMonthNet => currentMonthIncome - currentMonthExpense;
  bool get isSurplus => currentMonthNet >= 0;

  double get incomeChangePercent {
    if (prevMonthIncome == 0) return 0;
    return ((currentMonthIncome - prevMonthIncome) / prevMonthIncome) * 100;
  }

  double get expenseChangePercent {
    if (prevMonthExpense == 0) return 0;
    return ((currentMonthExpense - prevMonthExpense) / prevMonthExpense) * 100;
  }

  double get expenseToIncomeRatio {
    if (currentMonthIncome == 0) return 0;
    return (currentMonthExpense / currentMonthIncome).clamp(0.0, 1.0);
  }

  AnalyticsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<MonthlySummaryEntity>? monthlySummaries,
    List<CategoryBreakdownEntity>? categoryBreakdowns,
    List<WalletEntity>? wallets,
    DateTime? selectedMonth,
    String? selectedWalletId,
    int? totalBalance,
    int? currentMonthIncome,
    int? currentMonthExpense,
    int? prevMonthIncome,
    int? prevMonthExpense,
    bool clearError = false,
    bool clearWallet = false,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      monthlySummaries: monthlySummaries ?? this.monthlySummaries,
      categoryBreakdowns: categoryBreakdowns ?? this.categoryBreakdowns,
      wallets: wallets ?? this.wallets,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedWalletId: clearWallet ? null : (selectedWalletId ?? this.selectedWalletId),
      totalBalance: totalBalance ?? this.totalBalance,
      currentMonthIncome: currentMonthIncome ?? this.currentMonthIncome,
      currentMonthExpense: currentMonthExpense ?? this.currentMonthExpense,
      prevMonthIncome: prevMonthIncome ?? this.prevMonthIncome,
      prevMonthExpense: prevMonthExpense ?? this.prevMonthExpense,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier({required WalletRepository repository})
      : super(const AnalyticsState()) {
    _repository = repository;
  }

  late final WalletRepository _repository;

  Future<void> load(String userId) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final now = DateTime.now();
      final selectedMonth = state.selectedMonth ?? DateTime(now.year, now.month);

      // --- Fetch 6 months of data in parallel ---
      final futures = <Future>[];
      final months = _lastSixMonths(now);

      // Build monthly summaries
      for (final month in months) {
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

      // Also fetch wallets for total balance & wallet list
      futures.add(_repository.getWallets(userId));

      final results = await Future.wait(futures);

      // --- Process monthly summaries ---
      final summaries = <MonthlySummaryEntity>[];
      for (int i = 0; i < months.length; i++) {
        final transactions = results[i] as dynamic;
        int income = 0, expense = 0;
        for (final tx in transactions) {
          if (tx.isIncome) income += tx.amount as int;
          if (tx.isExpense) expense += tx.amount as int;
        }
        summaries.add(MonthlySummaryEntity(
          year: months[i].year,
          month: months[i].month,
          income: income,
          expense: expense,
        ));
      }

      // --- Wallets and Total balance ---
      final wallets = results.last as List<WalletEntity>;
      int totalBalance = 0;
      for (final w in wallets) {
        if (state.selectedWalletId == null || w.id == state.selectedWalletId) {
          totalBalance += w.balance;
        }
      }

      // --- Current & prev month ---
      final currentSummary = summaries.lastWhere(
        (s) => s.year == selectedMonth.year && s.month == selectedMonth.month,
        orElse: () => MonthlySummaryEntity(
            year: selectedMonth.year, month: selectedMonth.month, income: 0, expense: 0),
      );
      final prevMonthDate = DateTime(selectedMonth.year, selectedMonth.month - 1);
      final prevSummary = summaries.firstWhere(
        (s) => s.year == prevMonthDate.year && s.month == prevMonthDate.month,
        orElse: () => MonthlySummaryEntity(
            year: prevMonthDate.year, month: prevMonthDate.month, income: 0, expense: 0),
      );

      // --- Category breakdown (expense only, current month) ---
      final currentMonthIdx = months.indexWhere(
          (m) => m.year == selectedMonth.year && m.month == selectedMonth.month);
      final currentMonthTxs = currentMonthIdx >= 0
          ? results[currentMonthIdx] as dynamic
          : <dynamic>[];

      final categoryMap = <String, _CategoryAccum>{};
      for (final tx in currentMonthTxs) {
        if (!tx.isExpense) continue;
        final catId = tx.categoryId as String? ?? '__uncategorized__';
        final catName = tx.categoryName as String? ?? 'Lainnya';
        final catIcon = tx.categoryIcon as String?;
        final catColor = tx.categoryColor as String?;
        categoryMap.putIfAbsent(catId, () => _CategoryAccum(catName, catIcon, catColor));
        categoryMap[catId]!.amount += tx.amount as int;
        categoryMap[catId]!.count++;
      }

      final totalExpense = categoryMap.values.fold<int>(0, (s, c) => s + c.amount);
      final breakdowns = categoryMap.entries
          .map((e) => CategoryBreakdownEntity(
                categoryId: e.key,
                categoryName: e.value.name,
                categoryIcon: e.value.icon,
                categoryColor: e.value.color,
                totalAmount: e.value.amount,
                percentage: totalExpense == 0 ? 0 : e.value.amount / totalExpense,
                transactionCount: e.value.count,
              ))
          .toList()
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      // Insight is calculated in l10n now.

      state = state.copyWith(
        isLoading: false,
        monthlySummaries: summaries,
        categoryBreakdowns: breakdowns,
        wallets: wallets,
        selectedMonth: selectedMonth,
        totalBalance: totalBalance,
        currentMonthIncome: currentSummary.income,
        currentMonthExpense: currentSummary.expense,
        prevMonthIncome: prevSummary.income,
        prevMonthExpense: prevSummary.expense,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> changeMonth(String userId, DateTime month) async {
    state = state.copyWith(selectedMonth: month);
    await load(userId);
  }

  Future<void> changeWallet(String userId, String? walletId) async {
    if (walletId == null) {
      state = state.copyWith(clearWallet: true);
    } else {
      state = state.copyWith(selectedWalletId: walletId);
    }
    await load(userId);
  }

  List<DateTime> _lastSixMonths(DateTime now) {
    return List.generate(6, (i) {
      final m = now.month - 5 + i;
      final y = now.year + (m <= 0 ? -1 : 0);
      final adjustedM = m <= 0 ? m + 12 : m;
      return DateTime(y, adjustedM);
    });
  }
}

class _CategoryAccum {
  _CategoryAccum(this.name, this.icon, this.color);
  final String name;
  final String? icon;
  final String? color;
  int amount = 0;
  int count = 0;
}
