import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/wallet/domain/entities/transaction_entity.dart';
import 'package:nyimpeun/app/providers/wallet_providers.dart';
import 'package:nyimpeun/features/wallet/presentation/widgets/transaction_tile.dart';
import 'package:nyimpeun/features/wallet/presentation/views/add_transaction_page.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';

class TransactionListPage extends ConsumerStatefulWidget {
  const TransactionListPage({super.key});

  @override
  ConsumerState<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends ConsumerState<TransactionListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final authState = ref.read(authStateNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    ref.read(transactionListProvider.notifier).loadTransactions(
          userId: authState.user.id,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final authState = ref.read(authStateNotifierProvider);
      if (authState is AuthAuthenticated) {
        ref.read(transactionListProvider.notifier).loadMore(userId: authState.user.id);
      }
    }
  }

  List<dynamic> _buildGroupedTransactions(List<TransactionEntity> transactions) {
    final List<dynamic> items = [];
    String? currentDateStr;
    
    for (final tx in transactions) {
      final dateStr = _formatDateHeader(tx.date);
      if (currentDateStr != dateStr) {
        items.add(dateStr);
        currentDateStr = dateStr;
      }
      items.add(tx);
    }
    
    return items;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) {
      return 'Hari ini';
    } else if (txDate == yesterday) {
      return 'Kemarin';
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
    if (result == true) _loadInitialData();
  }

  void _showDeleteDialog(String transactionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Transaksi?'),
        content: const Text('Transaksi ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(transactionListProvider.notifier).deleteTransaction(transactionId);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Semua Transaksi',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: txState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : txState.transactions.isEmpty
              ? _EmptyTransactions()
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _buildGroupedTransactions(txState.transactions).length + 1,
                  itemBuilder: (context, index) {
                    final listItems = _buildGroupedTransactions(txState.transactions);
                    
                    if (index == listItems.length) {
                      return txState.hasMore
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox(height: 80);
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
                        onLongPress: () => _showDeleteDialog(tx.id),
                      ),
                    );
                  },
                ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'Belum ada transaksi',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
