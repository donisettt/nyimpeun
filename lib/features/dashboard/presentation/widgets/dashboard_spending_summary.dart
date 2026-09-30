import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/app/providers/dashboard_providers.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/dashboard/l10n/dashboard_l10n.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';

class DashboardSpendingSummary extends ConsumerWidget {
  const DashboardSpendingSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardSpendingProvider);
    final lang = ref.watch(languageProvider);
    final l10n = DashboardL10n.of(lang);
    final authState = ref.watch(authStateNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    // Use only categories with amount > 0
    final breakdowns = state.categoryBreakdowns.where((e) => e.totalAmount > 0).toList();
    // Sort by largest percentage first
    breakdowns.sort((a, b) => b.percentage.compareTo(a.percentage));
    
    // Fallback colors for categories in shades of indigo/purple as in mockup
    final colors = [
      const Color(0xFF667EEA), // Indigo
      const Color(0xFF7F9CF5), // Light Indigo
      const Color(0xFF4C51BF), // Dark Indigo
      const Color(0xFF9FA8DA), // Indigo Accent
      const Color(0xFFC3DAFE), // Very Light
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.expenseCategory,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (user == null || state.availableMonths.isEmpty) return;
                  _showMonthPicker(context, ref, user.id, state.availableMonths, state.selectedMonth, lang.code);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        state.selectedMonth != null
                            ? DateFormat.yMMMM(lang.code).format(state.selectedMonth!)
                            : l10n.thisMonth,
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (state.errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${state.errorMessage}', style: AppTypography.labelMedium.copyWith(color: AppColors.error)),
              ),
            )
          else if (breakdowns.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(l10n.noTransactionData, style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doughnut Chart
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2, // slight space between sections
                          centerSpaceRadius: 36, // size of inner hole
                          startDegreeOffset: -90,
                          sections: breakdowns.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final color = item.categoryColor != null 
                                ? Color(int.parse(item.categoryColor!.replaceAll('#', '0xFF')))
                                : colors[index % colors.length];
                                
                            return PieChartSectionData(
                              color: color,
                              value: item.percentage * 100,
                              title: '',
                              radius: 24, // thickness of the doughnut ring
                            );
                          }).toList(),
                        ),
                      ),
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: breakdowns.take(5).toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final color = item.categoryColor != null 
                          ? Color(int.parse(item.categoryColor!.replaceAll('#', '0xFF')))
                          : colors[index % colors.length];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.categoryName,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(item.percentage * 100).toStringAsFixed(0)}%',
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showMonthPicker(
    BuildContext context,
    WidgetRef ref,
    String userId,
    List<DateTime> availableMonths,
    DateTime? selectedMonth,
    String localeCode,
  ) {
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
                    final isSelected = selectedMonth != null &&
                        month.year == selectedMonth.year &&
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
                        ref.read(dashboardSpendingProvider.notifier).changeMonth(userId, month);
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
}
