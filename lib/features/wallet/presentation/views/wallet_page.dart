import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/wallet/domain/entities/transaction_entity.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';
import 'package:nyimpeun/features/wallet/presentation/widgets/add_wallet_sheet.dart';
import 'package:nyimpeun/features/wallet/presentation/views/add_transaction_page.dart';
import 'package:nyimpeun/features/wallet/presentation/widgets/transaction_tile.dart';
import 'package:nyimpeun/features/wallet/presentation/widgets/wallet_summary_header.dart';
import 'package:nyimpeun/features/wallet/presentation/views/transaction_list_page.dart';
import 'package:nyimpeun/app/providers/wallet_providers.dart';
import 'package:nyimpeun/core/utils/formatters.dart';
import 'package:nyimpeun/features/wallet/l10n/wallet_l10n.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final authState = ref.read(authStateNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    final userId = authState.user.id;

    ref.read(walletListProvider.notifier).loadWallets(userId).then((_) {
      final selectedWalletId =
          ref.read(walletListProvider).selectedWalletId;
      ref.read(transactionListProvider.notifier).loadTransactions(
            userId: userId,
            walletId: selectedWalletId,
          );
    });
  }

  void _reloadTransactionsForWallet(String walletId) {
    final authState = ref.read(authStateNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    ref.read(transactionListProvider.notifier).loadTransactions(
          userId: authState.user.id,
          walletId: walletId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletListProvider);
    final txState = ref.watch(transactionListProvider);
    final l10n = WalletL10n.of(ref.watch(languageProvider));

    return CustomScrollView(
      slivers: [
        // ── App Bar ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.pageTitle,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Summary Header ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: walletState.isLoading
                ? _SummaryShimmer()
                : WalletSummaryHeader(
                    selectedWallet: walletState.selectedWallet,
                    totalIncome: txState.totalIncome,
                    totalExpense: txState.totalExpense,
                    l10n: l10n,
                    onChangeWallet: () => _showChangeWalletSheet(l10n),
                  ),
          ),
        ),



        // ── Transactions Section ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.allTransactions,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionListPage(),
                      ),
                    );
                  },
                  child: Text(
                    l10n.seeAll,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Search Bar (UI only for now)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.search,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Transaction List ───────────────────────────────────────────────
        if (txState.isLoading)
          SliverToBoxAdapter(child: _TransactionShimmer())
        else if (txState.transactions.isEmpty)
          SliverToBoxAdapter(child: _EmptyTransactions(l10n: l10n))
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final listItems = _buildGroupedTransactions(txState.transactions, l10n);
                
                if (listItems.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        l10n.noRecentTransactions,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                if (index == listItems.length) {
                  return const SizedBox(height: 80);
                }

                final item = listItems[index];

                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Text(
                      item,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                final tx = item as TransactionEntity;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TransactionTile(
                    transaction: tx,
                    onTap: () => _openEditTransaction(tx),
                    onLongPress: () => _showDeleteDialog(tx.id, l10n),
                  ),
                );
              },
              childCount: _buildGroupedTransactions(txState.transactions, l10n).length + 1,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Future<void> _openAddWallet() async {
    final result = await showAddWalletSheet(context);
    if (result == true) _loadData();
  }

  Future<void> _openEditWallet(WalletEntity wallet) async {
    final result = await showAddWalletSheet(context, editEntity: wallet);
    if (result == true) _loadData();
  }

  void _showWalletOptions(WalletEntity wallet, WalletL10n l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              wallet.name,
              style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              wallet.type.label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: AppColors.primary, size: 20),
              ),
              title: Text(l10n.editWallet),
              onTap: () {
                Navigator.pop(ctx);
                _openEditWallet(wallet);
              },
            ),
            if (!wallet.isDefault)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 20),
                ),
                title: Text(l10n.deleteWallet,
                    style: const TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteWallet(wallet, l10n);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showChangeWalletSheet(WalletL10n l10n) {
    final wallets = ref.read(walletListProvider).wallets;
    final selectedId = ref.read(walletListProvider).selectedWalletId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.selectWallet,
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (wallets.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(l10n.emptyWalletTitle),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: wallets.length,
                    itemBuilder: (context, index) {
                      final w = wallets[index];
                      final isSelected = w.id == selectedId;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            w.type == WalletType.cash
                                ? Icons.account_balance_wallet_rounded
                                : w.type == WalletType.bank
                                    ? Icons.account_balance_rounded
                                    : Icons.phonelink_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          w.name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          AppFormatters.currency(w.balance.toDouble()),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary)
                            : IconButton(
                                icon: const Icon(Icons.more_vert_rounded,
                                    color: AppColors.textSecondary),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showWalletOptions(w, l10n);
                                },
                              ),
                        onTap: () {
                          ref
                              .read(walletListProvider.notifier)
                              .selectWallet(w.id);
                          Navigator.pop(ctx);
                          _reloadTransactionsForWallet(w.id);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openAddWallet();
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    l10n.addWallet,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteWallet(WalletEntity wallet, WalletL10n l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteWalletConfirmTitle),
        content: Text(
          l10n.deleteWalletConfirmDesc(wallet.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(walletListProvider.notifier)
                  .deleteWallet(wallet.id);
            },
            child: Text(l10n.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }


  List<dynamic> _buildGroupedTransactions(List<TransactionEntity> transactions, WalletL10n l10n) {
    final List<dynamic> items = [];
    String? currentDateStr;
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    
    for (final tx in transactions) {
      if (tx.date.isBefore(cutoffDate)) continue;

      final dateStr = _formatDateHeader(tx.date, l10n);
      if (currentDateStr != dateStr) {
        items.add(dateStr);
        currentDateStr = dateStr;
      }
      items.add(tx);
    }
    
    return items;
  }

  String _formatDateHeader(DateTime date, WalletL10n l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) {
      return l10n.today;
    } else if (txDate == yesterday) {
      return l10n.yesterday;
    } else {
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    }
  }

  Future<void> _openEditTransaction(TransactionEntity tx) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionPage(editEntity: tx),
      ),
    );
    if (result == true) _loadData();
  }

  void _showDeleteDialog(String transactionId, WalletL10n l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteTransaction),
        content: Text(
          l10n.deleteTransactionConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authState = ref.read(authStateNotifierProvider);
              await ref
                  .read(transactionListProvider.notifier)
                  .deleteTransaction(transactionId);
              // Reload wallet agar balance terupdate
              if (authState is AuthAuthenticated) {
                ref.read(walletListProvider.notifier).loadWallets(authState.user.id);
              }
            },
            child: Text(l10n.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────



class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.l10n});
  final WalletL10n l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            l10n.emptyTransactions,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer Skeletons (simple) ───────────────────────────────────────────────

class _SummaryShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Shimmer(height: 160, radius: 24);
}


class _TransactionShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _Shimmer(width: 48, height: 48, radius: 14),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Shimmer(height: 14, radius: 8),
                      const SizedBox(height: 6),
                      _Shimmer(height: 11, width: 100, radius: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _Shimmer(height: 14, width: 70, radius: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({this.width, required this.height, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmer,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
