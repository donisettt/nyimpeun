import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/providers/analytics_providers.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/app/providers/wallet_providers.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/core/utils/extensions.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/wallet/presentation/views/transaction_list_page.dart';
import 'package:nyimpeun/features/dashboard/l10n/dashboard_l10n.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';

class DashboardRecentTransactions extends ConsumerStatefulWidget {
  const DashboardRecentTransactions({super.key});

  @override
  ConsumerState<DashboardRecentTransactions> createState() => _DashboardRecentTransactionsState();
}

class _DashboardRecentTransactionsState extends ConsumerState<DashboardRecentTransactions> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  void _loadTransactions() {
    final authState = ref.read(authStateNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    if (user != null) {
      final selectedWalletId = ref.read(analyticsProvider).selectedWalletId;
      ref.read(transactionListProvider.notifier).loadTransactions(
        userId: user.id,
        walletId: selectedWalletId,
      );
    }
  }

  String _getCategoryIconPath(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty) {
      return 'assets/images/wallet/lainnya.webp';
    }

    final lower = categoryName.toLowerCase();
    if (lower.contains('belanja')) return 'assets/images/wallet/belanja.webp';
    if (lower.contains('bonus')) return 'assets/images/wallet/bonus.webp';
    if (lower.contains('gaji')) return 'assets/images/wallet/gaji.webp';
    if (lower.contains('hiburan')) return 'assets/images/wallet/hiburan.webp';
    if (lower.contains('investasi')) return 'assets/images/wallet/investasi.webp';
    if (lower.contains('kesehatan')) return 'assets/images/wallet/kesehatan.webp';
    if (lower.contains('makanan') || lower.contains('makan')) return 'assets/images/wallet/makanan.webp';
    if (lower.contains('tagihan')) return 'assets/images/wallet/tagihan.webp';
    if (lower.contains('transport')) return 'assets/images/wallet/transport.webp';

    return 'assets/images/wallet/lainnya.webp';
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in analytics selectedWalletId to reload transactions
    ref.listen(analyticsProvider.select((state) => state.selectedWalletId), (prev, next) {
      if (prev != next) {
        _loadTransactions();
      }
    });

    final txState = ref.watch(transactionListProvider);
    final transactions = txState.transactions.take(5).toList();
    final l10n = DashboardL10n.of(ref.watch(languageProvider));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentTransactions,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionListPage()),
                );
              },
              child: Row(
                children: [
                  Text(
                    l10n.seeAll,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (txState.isLoading && transactions.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ))
        else if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Center(
              child: Text(
                l10n.noTransactions,
                style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...transactions.map((tx) {
            final isExpense = tx.isExpense;
            final imagePath = _getCategoryIconPath(tx.categoryName);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      imagePath,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (tx.note != null && tx.note!.isNotEmpty) ? tx.note! : (tx.categoryName ?? 'Transaksi'),
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${isExpense ? l10n.outFlow : l10n.inFlow} • ${tx.date.toShortDate()}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isExpense ? '-' : '+'}${tx.amount.abs().toCurrency()}',
                        style: AppTypography.titleSmall.copyWith(
                          color: isExpense ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.categoryName ?? 'Lainnya',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
