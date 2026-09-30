import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/providers/analytics_providers.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/app/providers/dashboard_providers.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/core/utils/extensions.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/dashboard/l10n/dashboard_l10n.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';
import 'package:nyimpeun/features/analytics/presentation/viewmodels/analytics_viewmodel.dart';

class DashboardBalanceCard extends ConsumerStatefulWidget {
  const DashboardBalanceCard({super.key});

  @override
  ConsumerState<DashboardBalanceCard> createState() => _DashboardBalanceCardState();
}

class _DashboardBalanceCardState extends ConsumerState<DashboardBalanceCard> {
  bool _isHidden = false;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateNotifierProvider);
      if (authState is AuthAuthenticated) {
        ref.read(analyticsProvider.notifier).load(authState.user.id);
      }
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final authState = ref.watch(authStateNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final l10n = DashboardL10n.of(ref.watch(languageProvider));
    final rawWallets = List<WalletEntity>.from(state.wallets);
    // Sort so default is always first
    rawWallets.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return 0;
    });
    
    final walletList = rawWallets;

    // If selectedWalletId is null (default) and we have wallets, auto-select the first one
    if (state.selectedWalletId == null && walletList.isNotEmpty && user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(analyticsProvider.notifier).changeWallet(user.id, walletList.first.id);
        ref.read(dashboardSpendingProvider.notifier).load(user.id, walletId: walletList.first.id);
      });
    }

    // Sync _currentPage with selectedWalletId if changed from outside
    final selectedIndex = walletList.indexWhere((w) => w.id == state.selectedWalletId);
    final activeIndex = selectedIndex >= 0 ? selectedIndex : 0;
    
    if (_currentPage != activeIndex && _pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(activeIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      });
      _currentPage = activeIndex;
    }

    return Column(
      children: [
        SizedBox(
          height: 190, // Card height without extra margins
          child: PageView.builder(
            clipBehavior: Clip.none, // Allows shadow to render outside
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              if (user != null) {
                final walletId = walletList[index].id;
                ref.read(analyticsProvider.notifier).changeWallet(user.id, walletId);
                ref.read(dashboardSpendingProvider.notifier).load(user.id, walletId: walletId);
              }
            },
            itemCount: walletList.length,
            itemBuilder: (context, index) {
              final w = walletList[index];
              return _buildCard(w, state, l10n);
            },
          ),
        ),
        const SizedBox(height: 28), // Dedicated space for the soft shadow
        if (walletList.length > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(walletList.length, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: isActive ? 24 : 8,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 24), // Space between dots and Quick Actions
        ] else ...[
          const SizedBox(height: 16), // Space between shadow room and Quick Actions for 1 wallet
        ],
      ],
    );
  }

  Widget _buildCard(WalletEntity? activeWallet, AnalyticsState state, DashboardL10n l10n) {
    final balance = activeWallet?.balance ?? state.totalBalance;
    String walletName = activeWallet?.name ?? l10n.allAccounts;
    
    // Clean up duplicate names like "BCA – BCA" (case insensitive)
    if (walletName.contains('–')) {
      final parts = walletName.split('–').map((e) => e.trim()).toList();
      if (parts.length == 2 && parts[0].toLowerCase() == parts[1].toLowerCase()) {
        walletName = parts[0];
      }
    }

    final income = state.currentMonthIncome;
    final expense = state.currentMonthExpense;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Wallet Name & Hide Icon ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        walletName,
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isHidden = !_isHidden),
                child: Icon(
                  _isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Row 2: Balance ──
          Text(
            _isHidden ? 'Rp •••••••' : balance.toCurrency(),
            style: AppTypography.amountLarge.copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),

          const Spacer(),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 16),

          // ── Row 4: Income vs Expense ──
          Row(
            children: [
              // Income
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward_rounded, color: Colors.greenAccent, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.income, style: AppTypography.labelSmall.copyWith(color: Colors.white70, fontSize: 10)),
                          Text(
                            _isHidden ? '••••••' : income.toCurrency(),
                            style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                height: 32,
                width: 1,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 16),
              // Expense
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.redAccent, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.expense, style: AppTypography.labelSmall.copyWith(color: Colors.white70, fontSize: 10)),
                          Text(
                            _isHidden ? '••••••' : expense.toCurrency(),
                            style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
