import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/providers/analytics_providers.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/app/providers/dashboard_providers.dart';
import 'package:nyimpeun/app/providers/wallet_providers.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/analytics/presentation/views/analytics_page.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/auth/presentation/views/profile_page.dart';
import 'package:nyimpeun/features/dashboard/presentation/widgets/dashboard_balance_card.dart';
import 'package:nyimpeun/features/dashboard/presentation/widgets/dashboard_quick_actions.dart';
import 'package:nyimpeun/features/dashboard/presentation/widgets/dashboard_recent_transactions.dart';
import 'package:nyimpeun/features/dashboard/presentation/widgets/dashboard_spending_summary.dart';
import 'package:nyimpeun/features/dashboard/presentation/widgets/dashboard_top_bar.dart';
import 'package:nyimpeun/features/wallet/presentation/views/wallet_page.dart';
import 'package:nyimpeun/features/wallet/presentation/views/add_transaction_page.dart';
import 'package:nyimpeun/features/dashboard/l10n/dashboard_l10n.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    // Load semua data home saat pertama kali dashboard dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHomeData());
  }

  String get _userId {
    final authState = ref.read(authStateNotifierProvider);
    return authState is AuthAuthenticated ? authState.user.id : '';
  }

  /// Load/reload semua data yang dibutuhkan home tab
  Future<void> _loadHomeData() async {
    final uid = _userId;
    if (uid.isEmpty) return;

    final selectedWalletId = ref.read(analyticsProvider).selectedWalletId;

    await Future.wait([
      ref.read(walletListProvider.notifier).loadWallets(uid),
      ref.read(transactionListProvider.notifier).loadTransactions(userId: uid, walletId: selectedWalletId),
      ref.read(analyticsProvider.notifier).load(uid),
      ref.read(dashboardSpendingProvider.notifier).load(uid, walletId: selectedWalletId),
    ]);
  }

  /// Buka halaman tambah transaksi, lalu reload semua data setelah selesai
  Future<void> _openAddTransaction() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    );
    // result = true artinya transaksi berhasil disimpan
    if (result == true && mounted) {
      await _loadHomeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final l10n = DashboardL10n.of(ref.watch(languageProvider));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            // ── Index 0: Home ─────────────────────────────────────────────────
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadHomeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardTopBar(
                      user: user,
                      onLogout: () async {
                        await ref.read(authStateNotifierProvider.notifier).signOut();
                      },
                    ),
                    const SizedBox(height: 24),
                    const DashboardBalanceCard(),
                    // Spacing is handled internally by DashboardBalanceCard's shadow margin
                    const DashboardQuickActions(),
                    const SizedBox(height: 24),
                    const DashboardSpendingSummary(),
                    const SizedBox(height: 24),
                    const DashboardRecentTransactions(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Index 1: Wallet ───────────────────────────────────────────────
            const WalletPage(),

            // ── Index 2: Analytics ────────────────────────────────────────────
            const AnalyticsPage(),

            // ── Index 3: Profile ──────────────────────────────────────────────
            const ProfilePage(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 20,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 70,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.home_rounded, l10n.navHome),
              _buildNavItem(1, Icons.account_balance_wallet_outlined, l10n.navWallet),
              const SizedBox(width: 48),
              _buildNavItem(2, Icons.bar_chart_rounded, l10n.navAnalytics),
              _buildNavItem(3, Icons.person_outline_rounded, l10n.navProfile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

