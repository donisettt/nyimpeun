import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/app/providers/savings_providers.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/core/utils/formatters.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/savings/domain/entities/savings_goal_entity.dart';
import 'package:nyimpeun/features/savings/presentation/viewmodels/savings_viewmodel.dart';
import 'package:nyimpeun/features/savings/presentation/views/savings_detail_page.dart';
import 'package:nyimpeun/features/savings/presentation/widgets/add_contribution_sheet.dart';
import 'package:nyimpeun/features/savings/presentation/widgets/add_savings_goal_sheet.dart';
import 'package:nyimpeun/features/savings/presentation/widgets/savings_goal_card.dart';
import 'package:nyimpeun/features/savings/l10n/savings_l10n.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';

class SavingsPage extends ConsumerStatefulWidget {
  const SavingsPage({super.key});

  @override
  ConsumerState<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends ConsumerState<SavingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGoals());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadGoals() {
    final authState = ref.read(authStateNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    ref.read(savingsProvider.notifier).loadGoals(authState.user.id);
  }

  String get _userId {
    final authState = ref.read(authStateNotifierProvider);
    return authState is AuthAuthenticated ? authState.user.id : '';
  }

  Future<void> _openAddGoal() async {
    final result = await showAddSavingsGoalSheet(
      context,
      userId: _userId,
    );
    if (result == true) _loadGoals();
  }

  Future<void> _openContribute(SavingsGoalEntity goal) async {
    final result = await showAddContributionSheet(
      context,
      goal: goal,
      userId: _userId,
    );
    if (result == true) {
      _checkMilestone();
    }
  }

  void _checkMilestone() {
    final milestone = ref.read(savingsProvider).milestoneReached;
    if (milestone != null && mounted) {
      final l10n = SavingsL10n.of(ref.read(languageProvider));
      ref.read(savingsProvider.notifier).clearMilestone();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Milestone $milestone ${l10n.milestoneReached}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsProvider);
    final l10n = SavingsL10n.of(ref.watch(languageProvider));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.pageTitle,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: _loadGoals,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  if (state.goals.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _SummaryBanner(state: state, l10n: l10n),
                    ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        dividerColor: AppColors.border,
                        labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                        unselectedLabelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                        tabs: [
                          Tab(text: l10n.tabActive),
                          Tab(text: l10n.tabCompleted),
                          Tab(text: l10n.tabPaused),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _GoalsList(
                    goals: state.activeGoals,
                    emptyMessage: l10n.emptyActiveTitle,
                    emptySubtitle: l10n.emptyActiveSubtitle.replaceAll('\\n', '\n'),
                    onTap: (g) => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SavingsDetailPage(goal: g)),
                    ),
                    onContribute: _openContribute,
                  ),
                  _GoalsList(
                    goals: state.completedGoals,
                    emptyMessage: l10n.emptyCompletedTitle,
                    emptySubtitle: l10n.emptyCompletedSubtitle,
                    onTap: (g) => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SavingsDetailPage(goal: g)),
                    ),
                    onContribute: (_) {},
                  ),
                  _GoalsList(
                    goals: state.pausedGoals,
                    emptyMessage: l10n.emptyPausedTitle,
                    emptySubtitle: l10n.emptyPausedSubtitle,
                    onTap: (g) => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SavingsDetailPage(goal: g)),
                    ),
                    onContribute: (_) {},
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddGoal,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          l10n.createSavings,
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// ─── Summary Banner ───────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.state, required this.l10n});
  final SavingsState state;
  final SavingsL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalAllocated,
                    style: AppTypography.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.currency(state.totalSaved.toDouble()),
                    style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.totalTarget,
                    style: AppTypography.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.currency(state.totalTarget.toDouble()),
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.overallProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(state.overallProgress * 100).toStringAsFixed(1)}% ${l10n.ofAllTargets}',
                style: AppTypography.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
              ),
              Text(
                '${state.activeGoals.length} ${l10n.activeStatus} · ${state.completedGoals.length} ${l10n.completedStatus}',
                style: AppTypography.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Goals List ───────────────────────────────────────────────────────────────

class _GoalsList extends StatelessWidget {
  const _GoalsList({
    required this.goals,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.onTap,
    required this.onContribute,
  });

  final List<SavingsGoalEntity> goals;
  final String emptyMessage;
  final String emptySubtitle;
  final void Function(SavingsGoalEntity) onTap;
  final void Function(SavingsGoalEntity) onContribute;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.savings_outlined, size: 60, color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: goals.length,
      itemBuilder: (_, i) => SavingsGoalCard(
        goal: goals[i],
        onTap: () => onTap(goals[i]),
        onContribute: () => onContribute(goals[i]),
      ),
    );
  }
}
