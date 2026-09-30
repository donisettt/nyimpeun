import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.wallet,
    this.isSelected = false,
    this.onTap,
    this.onOptionsTap,
  });

  final WalletEntity wallet;
  final bool isSelected;
  final VoidCallback? onTap;
  /// Called when the ⋮ button is tapped — opens edit/delete menu
  final VoidCallback? onOptionsTap;

  static const _walletColors = {
    'cash': [Color(0xFF059669), Color(0xFF047857)],
    'bank': [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    'e-wallet': [Color(0xFF7C3AED), Color(0xFF6D28D9)],
  };

  static const _walletIcons = {
    'cash': Icons.account_balance_wallet_rounded,
    'bank': Icons.account_balance_rounded,
    'e-wallet': Icons.phonelink_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = _walletColors[wallet.type.value] ??
        [AppColors.primary, AppColors.primaryDark];
    final icon = _walletIcons[wallet.type.value] ?? Icons.wallet_rounded;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.white, width: 2.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: isSelected ? 0.4 : 0.2),
              blurRadius: isSelected ? 20 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: icon | badge | options button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 6),
                  // Default badge (flexible)
                  if (wallet.isDefault)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Utama',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  // ⋮ Options button — single tap
                  GestureDetector(
                    onTap: onOptionsTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Wallet name
              Text(
                wallet.name,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Balance
              Text(
                formatter.format(wallet.balance),
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
