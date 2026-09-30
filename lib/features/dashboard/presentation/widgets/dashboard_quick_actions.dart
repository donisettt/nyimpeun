import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/wallet/presentation/views/add_transaction_page.dart';
import 'package:nyimpeun/features/wallet/presentation/widgets/manage_categories_sheet.dart';
import 'package:nyimpeun/features/savings/presentation/views/savings_page.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/dashboard/l10n/dashboard_l10n.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';

class DashboardQuickActions extends ConsumerWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = DashboardL10n.of(ref.watch(languageProvider));
    final actions = [
      (
        label: l10n.income,
        imagePath: 'assets/images/home/quick_income.webp',
        icon: null,
        color: AppColors.success,
        type: 'income',
      ),
      (
        label: l10n.expense,
        imagePath: 'assets/images/home/quick_spending.webp',
        icon: null,
        color: AppColors.error,
        type: 'expense',
      ),
      (
        label: l10n.savings,
        imagePath: 'assets/images/home/quick_saving.webp',
        icon: null,
        color: AppColors.primary,
        type: 'saving',
      ),
      (
        label: l10n.categories,
        imagePath: 'assets/images/home/quick_category.webp',
        icon: null,
        color: AppColors.primary,
        type: 'category',
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        return _QuickActionItem(
          label: a.label,
          imagePath: a.imagePath,
          icon: a.icon,
          iconColor: a.color,
          onTap: () => _handleAction(context, ref, a.type),
        );
      }).toList(),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String type) async {
    switch (type) {
      case 'income':
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionPage(initialType: 'income')),
        );
        break;
      case 'expense':
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionPage(initialType: 'expense')),
        );
        break;
      case 'saving':
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const SavingsPage()),
        );
        break;
      case 'category':
        final authState = ref.read(authStateNotifierProvider);
        if (authState is AuthAuthenticated) {
          await showManageCategoriesSheet(
            context,
            userId: authState.user.id,
            type: 'expense',
          );
        }
        break;
    }
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.label,
    this.imagePath,
    this.icon,
    required this.iconColor,
    this.onTap,
  });

  final String label;
  final String? imagePath;
  final IconData? icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
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
            child: Center(
              child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    )
                  : Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
