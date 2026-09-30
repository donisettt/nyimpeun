import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyimpeun/app/providers/analytics_providers.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/core/utils/formatters.dart';
import 'package:nyimpeun/features/analytics/domain/entities/category_breakdown_entity.dart';
import 'package:nyimpeun/features/analytics/l10n/analytics_l10n.dart';
import 'package:nyimpeun/features/analytics/presentation/viewmodels/analytics_viewmodel.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final authState = ref.read(authStateNotifierProvider);
    if (authState is AuthAuthenticated) {
      ref.read(analyticsProvider.notifier).load(authState.user.id);
    }
  }

  String get _userId {
    final authState = ref.read(authStateNotifierProvider);
    return authState is AuthAuthenticated ? authState.user.id : '';
  }

  Future<void> _showWalletPicker(AnalyticsState state, AnalyticsL10n l10n) async {
    final w = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.walletPickerTitle,
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.apps_rounded, color: AppColors.primary),
                      title: Text(l10n.allWallets, style: AppTypography.bodyMedium),
                      onTap: () => Navigator.pop(ctx, '__ALL__'),
                      trailing: state.selectedWalletId == null ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                    ),
                    const Divider(height: 1),
                    ...state.wallets.map((wItem) => ListTile(
                      leading: Icon(
                        wItem.type == WalletType.cash
                            ? Icons.account_balance_wallet_rounded
                            : wItem.type == WalletType.bank
                                ? Icons.account_balance_rounded
                                : Icons.phonelink_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(wItem.name, style: AppTypography.bodyMedium),
                      subtitle: Text(AppFormatters.currency(wItem.balance.toDouble())),
                      trailing: state.selectedWalletId == wItem.id ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                      onTap: () => Navigator.pop(ctx, wItem.id),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (w != null) {
      ref.read(analyticsProvider.notifier).changeWallet(_userId, w == '__ALL__' ? null : w);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final l10n = AnalyticsL10n.of(ref.watch(languageProvider));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        titleSpacing: 20, // Tighter
        automaticallyImplyLeading: false,
        title: Text(
          l10n.pageTitle,
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          _MonthPicker(
            selectedMonth: state.selectedMonth ?? DateTime.now(),
            onChanged: (m) => ref
                .read(analyticsProvider.notifier)
                .changeMonth(_userId, m),
            localeCode: ref.watch(languageProvider).code,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () async => _load(),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), // Tighter padding
                children: [
                  // ── 1. Net Balance Card ───────────────────────────────
                  _NetBalanceCard(
                    state: state,
                    l10n: l10n,
                    onWalletTap: () => _showWalletPicker(state, l10n),
                  ),
                  const SizedBox(height: 12), // Tighter spacing

                  // ── 2. Insight Banner ─────────────────────────────────
                  if (l10n.getInsight(state) != null) ...[
                    _InsightBanner(
                      insight: l10n.getInsight(state)!,
                      isSurplus: state.isSurplus,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── 3. Income/Expense Donut Chart ─────────────────────
                  _DonutChartCard(state: state, l10n: l10n),
                  const SizedBox(height: 12),

                  // ── 4. 6-Month Bar Chart ──────────────────────────────
                  if (state.monthlySummaries.isNotEmpty) ...[
                    _BarChartCard(state: state, l10n: l10n),
                    const SizedBox(height: 12),
                  ],

                  // ── 5. Trend Comparison ───────────────────────────────
                  _TrendCard(state: state, l10n: l10n),
                  const SizedBox(height: 12),

                  // ── 6. Category Breakdown ─────────────────────────────
                  if (state.categoryBreakdowns.isNotEmpty) ...[
                    _CategoryBreakdownCard(
                      breakdowns: state.categoryBreakdowns,
                      l10n: l10n,
                    ),
                  ] else
                    _EmptyCategories(l10n: l10n),
                ],
              ),
            ),
    );
  }
}

// ─── Month Picker ─────────────────────────────────────────────────────────────

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.selectedMonth,
    required this.onChanged,
    required this.localeCode,
  });
  
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onChanged;
  final String localeCode;

  List<DateTime> _lastSixMonths() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      int m = now.month - i;
      int y = now.year;
      while (m <= 0) {
        m += 12;
        y -= 1;
      }
      return DateTime(y, m);
    });
  }

  void _showMonthSheet(BuildContext context) {
    final availableMonths = _lastSixMonths();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableMonths.length,
                  itemBuilder: (context, index) {
                    final month = availableMonths[index];
                    final isSelected = month.year == selectedMonth.year &&
                        month.month == selectedMonth.month;
                    return ListTile(
                      title: Text(
                        DateFormat.yMMMM(localeCode).format(month),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        onChanged(month);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMonthSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Tighter
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(16), // Softer radius
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.yMMM(localeCode).format(selectedMonth),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ─── Net Balance Card ─────────────────────────────────────────────────────────

class _NetBalanceCard extends StatelessWidget {
  const _NetBalanceCard({required this.state, required this.onWalletTap, required this.l10n});
  final AnalyticsState state;
  final VoidCallback onWalletTap;
  final AnalyticsL10n l10n;

  @override
  Widget build(BuildContext context) {
    final walletName = state.selectedWalletId == null
        ? l10n.allWallets
        : state.wallets.firstWhere((w) => w.id == state.selectedWalletId, orElse: () => state.wallets.first).name;

    return Container(
      padding: const EdgeInsets.all(20), // Reduced from 24
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20), // Reduced from 24
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onWalletTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.totalBalanceLabel(walletName),
                  style: AppTypography.labelSmall
                      .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white.withValues(alpha: 0.8)),
              ],
            ),
          ),
          const SizedBox(height: 4), // Tighter
          Text(
            AppFormatters.currency(state.totalBalance.toDouble()),
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 26, // Slightly smaller
            ),
          ),
          const SizedBox(height: 16), // Tighter
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12), // Tighter
          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                  label: l10n.incomeThisMonth,
                  value: AppFormatters.currency(state.currentMonthIncome.toDouble()),
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFF34D399),
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24), // Tighter height
              Expanded(
                child: _BalanceItem(
                  label: l10n.expenseLabel,
                  value: AppFormatters.currency(state.currentMonthExpense.toDouble()),
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFFFCA5A5),
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.align = CrossAxisAlignment.start,
  });
  final String label, value;
  final IconData icon;
  final Color iconColor;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisAlignment: align == CrossAxisAlignment.end
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 12, color: iconColor), // Smaller icon
            const SizedBox(width: 4),
            Text(label,
                style: AppTypography.labelSmall
                    .copyWith(color: Colors.white.withValues(alpha: 0.75), fontSize: 10)),
          ],
        ),
        const SizedBox(height: 2), // Tighter
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Insight Banner ───────────────────────────────────────────────────────────

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({required this.insight, required this.isSurplus});
  final String insight;
  final bool isSurplus;

  @override
  Widget build(BuildContext context) {
    final color = isSurplus ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final bgColor = isSurplus ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
    final icon = isSurplus ? Icons.trending_up_rounded : Icons.info_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), // Tighter padding
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insight,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Donut Chart Card ─────────────────────────────────────────────────────────

class _DonutChartCard extends StatefulWidget {
  const _DonutChartCard({required this.state, required this.l10n});
  final AnalyticsState state;
  final AnalyticsL10n l10n;

  @override
  State<_DonutChartCard> createState() => _DonutChartCardState();
}

class _DonutChartCardState extends State<_DonutChartCard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final income = widget.state.currentMonthIncome;
    final expense = widget.state.currentMonthExpense;
    final net = widget.state.currentMonthNet;
    final hasData = income > 0 || expense > 0;
    final l10n = widget.l10n;

    return _SectionCard(
      title: l10n.chartIncomeVsExpense,
      child: hasData
          ? Row( // Changed from Column to Row for better space utilization
              children: [
                SizedBox(
                  height: 120, // Smaller chart
                  width: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                _touchedIndex = response?.touchedSection
                                        ?.touchedSectionIndex ??
                                    -1;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2, // Tighter
                          centerSpaceRadius: 45, // Smaller center
                          sections: [
                            PieChartSectionData(
                              color: const Color(0xFF34D399),
                              value: income.toDouble(),
                              title: '',
                              radius: _touchedIndex == 0 ? 18 : 14,
                            ),
                            PieChartSectionData(
                              color: const Color(0xFFF87171),
                              value: expense.toDouble(),
                              title: '',
                              radius: _touchedIndex == 1 ? 18 : 14,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            net >= 0 ? l10n.surplus : l10n.deficit,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            AppFormatters.compactCurrency(net.abs().toDouble()), // Use compact currency for space
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: net >= 0
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Legend(
                          color: const Color(0xFF34D399),
                          label: l10n.incomeLabel,
                          value: AppFormatters.currency(income.toDouble())),
                      const SizedBox(height: 12), // Tighter
                      _Legend(
                          color: const Color(0xFFF87171),
                          label: l10n.expenseLabel,
                          value: AppFormatters.currency(expense.toDouble())),
                    ],
                  ),
                ),
              ],
            )
          : _EmptyChart(message: l10n.noDataThisMonth),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.bodySmall
                .copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─── Bar Chart (6 bulan) ──────────────────────────────────────────────────────

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({required this.state, required this.l10n});
  final AnalyticsState state;
  final AnalyticsL10n l10n;

  @override
  Widget build(BuildContext context) {
    final summaries = state.monthlySummaries;
    final maxVal = summaries.fold<int>(
      1,
      (prev, s) => max(prev, max(s.income, s.expense)),
    ).toDouble();

    return _SectionCard(
      title: l10n.barChartTitle,
      child: SizedBox(
        height: 150, // Reduced from 200
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.2,
            minY: 0,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.textPrimary.withValues(alpha: 0.9),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final s = summaries[groupIndex];
                  final label = rodIndex == 0 ? l10n.barTooltipIncome : l10n.barTooltipExpense;
                  final val = rodIndex == 0 ? s.income : s.expense;
                  return BarTooltipItem(
                    '$label\n${AppFormatters.currency(val.toDouble())}',
                    const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx < 0 || idx >= summaries.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        summaries[idx].monthLabel,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9, // Smaller font
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (val) => FlLine(
                color: AppColors.border,
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: summaries.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final isSelected = state.selectedMonth != null &&
                  s.year == state.selectedMonth!.year &&
                  s.month == state.selectedMonth!.month;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: s.income.toDouble(),
                    color: isSelected
                        ? const Color(0xFF34D399)
                        : const Color(0xFF34D399).withValues(alpha: 0.5),
                    width: 6, // Slimmer bars
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                  BarChartRodData(
                    toY: s.expense.toDouble(),
                    color: isSelected
                        ? const Color(0xFFF87171)
                        : const Color(0xFFF87171).withValues(alpha: 0.5),
                    width: 6, // Slimmer bars
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Trend Comparison ─────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.state, required this.l10n});
  final AnalyticsState state;
  final AnalyticsL10n l10n;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: l10n.trendTitle,
      child: Column(
        children: [
          _TrendRow(
            label: l10n.incomeLabel,
            currentVal: state.currentMonthIncome,
            changePercent: state.incomeChangePercent,
            positiveIsGood: true,
            sameLabel: l10n.trendSame,
          ),
          const Divider(height: 16, color: AppColors.border), // Tighter divider
          _TrendRow(
            label: l10n.expenseLabel,
            currentVal: state.currentMonthExpense,
            changePercent: state.expenseChangePercent,
            positiveIsGood: false,
            sameLabel: l10n.trendSame,
          ),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.label,
    required this.currentVal,
    required this.changePercent,
    required this.positiveIsGood,
    required this.sameLabel,
  });
  final String label;
  final int currentVal;
  final double changePercent;
  final bool positiveIsGood;
  final String sameLabel;

  @override
  Widget build(BuildContext context) {
    final isUp = changePercent > 0;
    final isGood = positiveIsGood ? isUp : !isUp;
    final color = changePercent == 0
        ? AppColors.textMuted
        : isGood
            ? const Color(0xFF059669)
            : const Color(0xFFDC2626);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textSecondary, fontSize: 10)),
              const SizedBox(height: 2),
              Text(
                AppFormatters.currency(currentVal.toDouble()),
                style: AppTypography.bodySmall
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        if (changePercent != 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Tighter
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 10, // Smaller
                  color: color,
                ),
                const SizedBox(width: 2),
                Text(
                  '${changePercent.abs().toStringAsFixed(1)}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 9, // Smaller
                  ),
                ),
              ],
            ),
          )
        else
          Text(sameLabel,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ─── Category Breakdown ───────────────────────────────────────────────────────

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.breakdowns, required this.l10n});
  final List<CategoryBreakdownEntity> breakdowns;
  final AnalyticsL10n l10n;

  static const _palette = [
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
    Color(0xFF84CC16),
  ];

  Color _colorFor(int index) => _palette[index % _palette.length];

  Widget _buildCategoryIcon(String categoryName, Color color) {
    String path = 'assets/images/wallet/lainnya.webp';
    final lower = categoryName.toLowerCase();
    if (lower.contains('belanja')) { path = 'assets/images/wallet/belanja.webp'; }
    else if (lower.contains('bonus')) { path = 'assets/images/wallet/bonus.webp'; }
    else if (lower.contains('gaji')) { path = 'assets/images/wallet/gaji.webp'; }
    else if (lower.contains('hiburan')) { path = 'assets/images/wallet/hiburan.webp'; }
    else if (lower.contains('investasi')) { path = 'assets/images/wallet/investasi.webp'; }
    else if (lower.contains('kesehatan')) { path = 'assets/images/wallet/kesehatan.webp'; }
    else if (lower.contains('makanan') || lower.contains('makan')) { path = 'assets/images/wallet/makanan.webp'; }
    else if (lower.contains('tagihan')) { path = 'assets/images/wallet/tagihan.webp'; }
    else if (lower.contains('transport')) { path = 'assets/images/wallet/transport.webp'; }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        path, 
        width: 28, 
        height: 28, 
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Icon(Icons.category_rounded, size: 14, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topItems = breakdowns.take(6).toList();

    return _SectionCard(
      title: l10n.categoryBreakdownTitle,
      child: Column(
        children: topItems.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          final color = _colorFor(i);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12), // Tighter
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 28, // Smaller icon container
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: _buildCategoryIcon(cat.categoryName, color),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.categoryName,
                        style: AppTypography.labelSmall
                            .copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(cat.percentage * 100).toStringAsFixed(1)}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppFormatters.compactCurrency(cat.totalAmount.toDouble()), // Use compact currency
                      style: AppTypography.labelSmall
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: cat.percentage,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4, // Slimmer progress bar
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Reusable Section Card ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Reduced from 20
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02), // Subtler shadow
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelLarge // Slightly smaller title
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12), // Tighter
          child,
        ],
      ),
    );
  }
}

// ─── Empty States ─────────────────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20), // Tighter
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 32, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(message,
                style: AppTypography.labelSmall // Smaller
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories({required this.l10n});
  final AnalyticsL10n l10n;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: l10n.categoryBreakdownTitle,
      child: _EmptyChart(message: l10n.noCategoryThisMonth),
    );
  }
}
