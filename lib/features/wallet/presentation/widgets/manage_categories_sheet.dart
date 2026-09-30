import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/app/providers/wallet_providers.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/wallet/domain/entities/category_entity.dart';
import 'package:nyimpeun/features/wallet/domain/entities/transaction_entity.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';
import 'package:nyimpeun/features/wallet/l10n/wallet_l10n.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';

// ─── Manage Categories Sheet ──────────────────────────────────────────────────

Future<void> showManageCategoriesSheet(
  BuildContext context, {
  required String userId,
  required String type,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ManageCategoriesSheet(userId: userId, type: type),
  );
}

class ManageCategoriesSheet extends ConsumerStatefulWidget {
  const ManageCategoriesSheet({
    super.key,
    required this.userId,
    required this.type,
  });
  final String userId;
  final String type;

  @override
  ConsumerState<ManageCategoriesSheet> createState() =>
      _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState
    extends ConsumerState<ManageCategoriesSheet> {
  final _nameCtrl = TextEditingController();
  bool _isAdding = false;

  // Preset colors
  final _colors = [
    '#F97316', '#3B82F6', '#EC4899', '#8B5CF6',
    '#10B981', '#F59E0B', '#EF4444', '#6B7280',
    '#059669', '#2563EB', '#7C3AED', '#DC2626',
  ];
  String _selectedColor = '#3B82F6';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isAdding = true);
    await ref.read(categoryProvider.notifier).addCategory(
          userId: widget.userId,
          name: name,
          type: widget.type,
          color: _selectedColor,
        );

    _nameCtrl.clear();
    setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    final catState = ref.watch(categoryProvider);
    final l10n = WalletL10n.of(ref.watch(languageProvider));
    final cats = widget.type == 'income'
        ? catState.incomeCategories
        : catState.expenseCategories;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 20, 24, keyboardHeight + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.manageLabel,
                        style: AppTypography.titleLarge
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.type == 'income' ? l10n.incomeCategory : l10n.expenseCategory,
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),

                  // Add new category
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.addNewCategory,
                            style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameCtrl,
                                style: AppTypography.bodyMedium,
                                decoration: InputDecoration(
                                  hintText: l10n.categoryName,
                                  hintStyle: AppTypography.bodyMedium
                                      .copyWith(color: AppColors.textMuted),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isAdding ? null : _addCategory,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  elevation: 0,
                                ),
                                child: _isAdding
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.add_rounded, size: 22),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Color picker
                        Text(l10n.pickColor,
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _colors.map((hex) {
                            final color =
                                Color(int.parse(hex.replaceFirst('#', '0xFF')));
                            final isSelected = _selectedColor == hex;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedColor = hex),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white, width: 2)
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 16)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Category list
                  Text(
                    l10n.availableCategories(cats.length),
                    style: AppTypography.titleSmall
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),

                  if (cats.isEmpty)
                    Text(l10n.noCategory,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted))
                  else
                    ...cats.map((c) {

                      final imagePath = _getCategoryIconPath(c.name);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            imagePath,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(c.name,
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                        subtitle: c.isDefault
                            ? Text('Default',
                                style: AppTypography.labelSmall
                                    .copyWith(color: AppColors.textMuted))
                            : null,
                        trailing: c.isDefault
                            ? null
                            : IconButton(
                                onPressed: () => _confirmDelete(c),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.error, size: 20),
                              ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(CategoryEntity c) {
    final l10n = WalletL10n.of(ref.read(languageProvider));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteCategory),
        content: Text(l10n.deleteCategoryConfirm(c.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(categoryProvider.notifier).deleteCategory(c.id);
            },
            child: Text(l10n.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
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
