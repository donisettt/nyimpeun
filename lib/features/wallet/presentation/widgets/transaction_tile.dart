import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/wallet/domain/entities/transaction_entity.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
  });

  final TransactionEntity transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;


  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final timeStr = DateFormat('HH:mm').format(transaction.date);

    final isIncome = transaction.isIncome;
    final isTransfer = transaction.isTransfer;
    final amountColor = isIncome
        ? const Color(0xFF059669) // Deeper green
        : isTransfer
            ? AppColors.primary
            : const Color(0xFFDC2626); // Deeper red
    final amountPrefix = isIncome ? '+' : isTransfer ? '⇄ ' : '-';

    final imagePath = _getCategoryIconPath(transaction.categoryName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagePath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        transaction.categoryName ?? _typeLabel(transaction.type),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              transaction.note?.isNotEmpty == true
                                  ? transaction.note!
                                  : (transaction.walletName ?? 'Dompet'),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Amount and Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$amountPrefix${formatter.format(transaction.amount)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'Pemasukan';
      case TransactionType.expense:
        return 'Pengeluaran';
      case TransactionType.transfer:
        return 'Transfer';
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
}
