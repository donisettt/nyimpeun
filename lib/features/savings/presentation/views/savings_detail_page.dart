import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/app/providers/savings_providers.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/core/utils/formatters.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/savings/domain/entities/savings_contribution_entity.dart';
import 'package:nyimpeun/features/savings/domain/entities/savings_goal_entity.dart';
import 'package:nyimpeun/features/savings/presentation/widgets/add_contribution_sheet.dart';
import 'package:nyimpeun/features/savings/presentation/widgets/add_savings_goal_sheet.dart';
import 'package:nyimpeun/features/savings/l10n/savings_l10n.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';

class SavingsDetailPage extends ConsumerStatefulWidget {
  const SavingsDetailPage({super.key, required this.goal});

  final SavingsGoalEntity goal;

  @override
  ConsumerState<SavingsDetailPage> createState() => _SavingsDetailPageState();
}

class _SavingsDetailPageState extends ConsumerState<SavingsDetailPage> {
  late SavingsGoalEntity _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContribs());
  }

  void _loadContribs() {
    ref.read(savingsProvider.notifier).loadContributions(_goal.id);
  }

  Color get _accentColor {
    try {
      return Color(int.parse(
          'FF${(_goal.color ?? '#2563EB').replaceAll('#', '')}',
          radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  void _syncGoalFromState() {
    final updated = ref
        .read(savingsProvider)
        .goals
        .firstWhere((g) => g.id == _goal.id, orElse: () => _goal);
    if (mounted) setState(() => _goal = updated);
  }

  Future<void> _openContribute() async {
    final authState = ref.read(authStateNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    final result = await showAddContributionSheet(
      context,
      goal: _goal,
      userId: authState.user.id,
    );

    if (result == true) {
      _syncGoalFromState();
      _loadContribs();
      _checkMilestone();
    }
  }

  void _checkMilestone() {
    final milestone = ref.read(savingsProvider).milestoneReached;
    if (milestone != null) {
      ref.read(savingsProvider.notifier).clearMilestone();
      final l10n = SavingsL10n.of(ref.read(languageProvider));
      _showMilestoneCelebration(milestone, l10n);
    }
  }

  void _showMilestoneCelebration(String milestone, SavingsL10n l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              'Milestone $milestone ${l10n.milestoneReachedDialogTitle}',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Kamu sudah mencapai $milestone dari target tabungan "${_goal.name}". Terus semangat! 💪',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.btnContinue,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit() async {
    final authState = ref.read(authStateNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    final result = await showAddSavingsGoalSheet(
      context,
      editGoal: _goal,
      userId: authState.user.id,
    );
    if (result == true) _syncGoalFromState();
  }

  Future<void> _toggleStatus() async {
    final newStatus = _goal.status == 'paused' ? 'active' : 'paused';
    await ref
        .read(savingsProvider.notifier)
        .toggleStatus(_goal.id, newStatus);
    _syncGoalFromState();
  }

  Future<void> _deleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(SavingsL10n.of(ref.read(languageProvider)).deleteGoalTitle),
        content: Text(
            'Goal "${_goal.name}" akan dihapus beserta semua riwayat kontribusinya.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(savingsProvider.notifier).deleteGoal(_goal.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor, Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);
    final dateFormatter = DateFormat('d MMM yyyy', 'id_ID');
    final timeFormatter = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Detail Tabungan',
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: _openEdit,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            onSelected: (v) {
              if (v == 'toggle') _toggleStatus();
              if (v == 'delete') _deleteGoal();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      _goal.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(_goal.isPaused ? 'Aktifkan' : 'Jeda Tabungan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Hapus', style: const TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Goal Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(_goal.icon ?? '🎯', style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _goal.name,
                              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (_goal.linkedWalletName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_balance_rounded, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Ke: ${_goal.linkedWalletName}',
                                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 2. Main Balance
                  Text(
                    'Dialokasikan',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.currency(_goal.currentAmount.toDouble()),
                        style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '/ ${AppFormatters.currency(_goal.targetAmount.toDouble())}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _goal.progressPercent,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_goal.progressPercent * 100).toStringAsFixed(1)}% Tercapai',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Sisa ${AppFormatters.currency(_goal.remainingAmount.toDouble())}',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 4. Details / Stats Grid
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Target Selesai',
                          _goal.deadline != null ? dateFormatter.format(_goal.deadline!) : 'Tidak ada',
                          Icons.flag_rounded,
                        ),
                        if (_goal.daysLeft != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          _buildDetailRow(
                            'Sisa Waktu',
                            '${_goal.daysLeft} hari lagi',
                            Icons.schedule_rounded,
                            valueColor: _goal.daysLeft! <= 7 ? AppColors.error : AppColors.textPrimary,
                          ),
                        ],
                        if (_goal.autoAllocatePercent > 0) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          _buildDetailRow(
                            'Auto-Alokasi',
                            '${_goal.autoAllocatePercent}% dari pemasukan',
                            Icons.auto_mode_rounded,
                            iconColor: _accentColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 5. History
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Riwayat Kontribusi',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        '${state.contributions.length} transaksi',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (state.isContribLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ))
                  else if (state.contributions.isEmpty)
                    const _EmptyContribs()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.contributions.length,
                      separatorBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(left: 48),
                        child: Divider(height: 1, color: AppColors.border),
                      ),
                      itemBuilder: (_, i) {
                        final c = state.contributions[i];
                        return _ContributionTile(
                          contribution: c,
                          formatter: timeFormatter,
                        );
                      },
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _goal.isCompleted || _goal.isPaused
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _openContribute,
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text('Tambah Kontribusi', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ContributionTile extends StatelessWidget {
  const _ContributionTile({
    required this.contribution,
    required this.formatter,
  });
  final SavingsContributionEntity contribution;
  final DateFormat formatter;

  @override
  Widget build(BuildContext context) {
    final isAuto = contribution.type == 'auto_allocate';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              isAuto ? Icons.auto_mode_rounded : Icons.south_west_rounded,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAuto ? 'Auto-alokasi' : (contribution.note ?? 'Transfer masuk'),
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
                if (contribution.createdAt != null)
                  Text(
                    formatter.format(contribution.createdAt!),
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          Text(
            '+${AppFormatters.currency(contribution.amount.toDouble())}',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyContribs extends StatelessWidget {
  const _EmptyContribs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 40, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Kontribusi akan muncul di sini',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
