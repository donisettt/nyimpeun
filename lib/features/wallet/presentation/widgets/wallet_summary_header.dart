import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';
import 'package:nyimpeun/features/wallet/l10n/wallet_l10n.dart';

class WalletSummaryHeader extends StatelessWidget {
  const WalletSummaryHeader({
    super.key,
    required this.selectedWallet,
    required this.totalIncome,
    required this.totalExpense,
    required this.l10n,
    this.onChangeWallet,
  });

  final WalletEntity? selectedWallet;
  final int totalIncome;
  final int totalExpense;
  final WalletL10n l10n;
  final VoidCallback? onChangeWallet;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final walletName = selectedWallet?.name ?? l10n.selectWallet;
    final balance = selectedWallet?.balance ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Wallet Text (Only show if default)
        if (selectedWallet?.isDefault ?? false) ...[
          Text(
            l10n.mainWallet,
            style: AppTypography.labelLarge.copyWith(
              color: const Color(0xFF4B5563), // Slate 600
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Balance & Change Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                formatter.format(balance),
                style: AppTypography.headlineMedium.copyWith(
                  color: const Color(0xFF1F2937), // Slate 800
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onChangeWallet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                ),
                child: Text(
                  l10n.changeWallet,
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (selectedWallet != null) ...[
          const SizedBox(height: 4),
          Text(
            walletName,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Income / Expense row
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: l10n.income,
                amount: formatter.format(totalIncome),
                icon: Icons.arrow_outward_rounded,
                iconColor: const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: l10n.expense,
                amount: formatter.format(totalExpense),
                icon: Icons.south_west_rounded,
                iconColor: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background shape at bottom right
            Positioned(
              right: -10,
              bottom: -10,
              child: Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF), // Light indigo/purple
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: iconColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: AppTypography.labelMedium.copyWith(
                          color: const Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    amount,
                    style: AppTypography.labelLarge.copyWith(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
