import 'package:flutter/material.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/core/utils/formatters.dart';
import 'package:nyimpeun/features/savings/domain/entities/savings_goal_entity.dart';

class SavingsGoalCard extends StatelessWidget {
  const SavingsGoalCard({
    super.key,
    required this.goal,
    required this.onTap,
    required this.onContribute,
  });

  final SavingsGoalEntity goal;
  final VoidCallback onTap;
  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(goal.color) ?? AppColors.primary;
    final lightColor = color.withValues(alpha: 0.12);
    final progress = goal.progressPercent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      goal.icon ?? '🎯',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (goal.hasLinkedWallet) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.account_balance_rounded,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              goal.linkedWalletName ?? '',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
                // Percentage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(status: goal.status),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: lightColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  goal.isCompleted ? Colors.green : color,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),

            // Amounts row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dialokasikan',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textMuted)),
                    Text(
                      AppFormatters.currency(goal.currentAmount.toDouble()),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Target',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textMuted)),
                    Text(
                      AppFormatters.currency(goal.targetAmount.toDouble()),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Deadline + Contribute button
            Row(
              children: [
                if (goal.daysLeft != null) ...[
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: goal.daysLeft! <= 7
                        ? AppColors.error
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    goal.daysLeft! <= 0
                        ? 'Sudah lewat deadline'
                        : '${goal.daysLeft} hari lagi',
                    style: AppTypography.labelSmall.copyWith(
                      color: goal.daysLeft! <= 7
                          ? AppColors.error
                          : AppColors.textMuted,
                    ),
                  ),
                ] else
                  Text(
                    'Tanpa deadline',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                const Spacer(),
                if (!goal.isCompleted && !goal.isPaused)
                  GestureDetector(
                    onTap: onContribute,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline_rounded, size: 16, color: color),
                          const SizedBox(width: 4),
                          Text(
                            'Tambah',
                            style: AppTypography.labelSmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (goal.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Tercapai',
                          style: AppTypography.labelSmall.copyWith(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Aktif', AppColors.primary),
      'paused' => ('Dijeda', AppColors.warning),
      'completed' => ('Selesai', Colors.green),
      _ => ('Aktif', AppColors.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}
