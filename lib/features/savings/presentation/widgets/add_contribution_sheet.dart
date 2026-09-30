import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/providers/savings_providers.dart';
import 'package:nyimpeun/app/providers/wallet_providers.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/core/utils/formatters.dart';
import 'package:nyimpeun/features/savings/domain/entities/savings_goal_entity.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';

Future<bool?> showAddContributionSheet(
  BuildContext context, {
  required SavingsGoalEntity goal,
  required String userId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddContributionSheet(goal: goal, userId: userId),
  );
}

class AddContributionSheet extends ConsumerStatefulWidget {
  const AddContributionSheet({
    super.key,
    required this.goal,
    required this.userId,
  });

  final SavingsGoalEntity goal;
  final String userId;

  @override
  ConsumerState<AddContributionSheet> createState() =>
      _AddContributionSheetState();
}

class _AddContributionSheetState extends ConsumerState<AddContributionSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;
  WalletEntity? _sourceWallet; // Dari rekening mana

  static const _presets = [50000, 100000, 250000, 500000];

  @override
  void initState() {
    super.initState();
    // Default source: pilih dompet yang bukan linked wallet (biasanya rekening utama)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallets = ref.read(walletListProvider).wallets;
      // Pick default wallet yang bukan linked wallet
      final defaultWallet = wallets
          .where((w) => w.id != widget.goal.linkedWalletId)
          .firstOrNull;
      if (defaultWallet != null && mounted) {
        setState(() => _sourceWallet = defaultWallet);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  int get _parsedAmount {
    final raw = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(raw) ?? 0;
  }

  void _applyPreset(int amount) {
    _amountCtrl.text = _formatThousands(amount.toString());
  }

  String _formatThousands(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  Future<void> _pickSourceWallet() async {
    final wallets = ref.read(walletListProvider).wallets
        .where((w) => w.id != widget.goal.linkedWalletId)
        .toList();

    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak ada rekening lain selain rekening tabungan')),
      );
      return;
    }

    final selected = await showModalBottomSheet<WalletEntity>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transfer dari Rekening',
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Pilih rekening sumber dana yang akan ditransfer ke ${widget.goal.linkedWalletName ?? 'rekening tabungan'}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: wallets.length,
              itemBuilder: (ctx, i) {
                final w = wallets[i];
                final isSelected = _sourceWallet?.id == w.id;
                final insufficientBalance = w.balance < (_parsedAmount > 0 ? _parsedAmount : 0);
                return ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
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
                  title: Text(w.name,
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    AppFormatters.currency(w.balance.toDouble()),
                    style: AppTypography.labelSmall.copyWith(
                      color: insufficientBalance && _parsedAmount > 0
                          ? AppColors.error
                          : AppColors.textMuted,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, w),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (selected != null) setState(() => _sourceWallet = selected);
  }

  Future<void> _submit() async {
    if (_parsedAmount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Masukkan nominal yang valid')));
      return;
    }
    if (_sourceWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih rekening sumber terlebih dahulu')));
      return;
    }
    if (_sourceWallet!.balance < _parsedAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Saldo ${_sourceWallet!.name} tidak cukup. Tersedia: ${AppFormatters.currency(_sourceWallet!.balance.toDouble())}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref.read(savingsProvider.notifier).contribute(
          goal: widget.goal,
          userId: widget.userId,
          amount: _parsedAmount,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          sourceWalletId: _sourceWallet!.id,
          sourceWalletName: _sourceWallet!.name,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  ref.read(savingsProvider).errorMessage ?? 'Gagal menambahkan kontribusi')),
        );
      }
    }
  }

  Color get _accentColor {
    try {
      return Color(
          int.parse('FF${(widget.goal.color ?? '#2563EB').replaceAll('#', '')}',
              radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final remaining = widget.goal.remainingAmount;

    return Container(
      margin: const EdgeInsets.only(top: 60),
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
              padding:
                  EdgeInsets.fromLTRB(24, 20, 24, keyboardHeight + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nabung ke Goal',
                            style: AppTypography.titleLarge
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(widget.goal.icon ?? '',
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                widget.goal.name,
                                style: AppTypography.bodySmall
                                    .copyWith(color: _accentColor,
                                        fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Transfer flow illustration
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _accentColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        // Source wallet row
                        GestureDetector(
                          onTap: _pickSourceWallet,
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(Icons.account_balance_rounded,
                                    size: 18, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Dari rekening',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                                color: AppColors.textMuted)),
                                    Text(
                                      _sourceWallet?.name ??
                                          'Pilih rekening...',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _sourceWallet != null
                                            ? AppColors.textPrimary
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                    if (_sourceWallet != null)
                                      Text(
                                        'Saldo: ${AppFormatters.currency(_sourceWallet!.balance.toDouble())}',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                                color: AppColors.textMuted),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit_rounded,
                                  size: 16, color: AppColors.textMuted),
                            ],
                          ),
                        ),

                        // Arrow
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Icon(Icons.arrow_downward_rounded,
                                  color: _accentColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Transfer ke',
                                style: AppTypography.labelSmall
                                    .copyWith(color: _accentColor),
                              ),
                            ],
                          ),
                        ),

                        // Destination wallet
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(widget.goal.icon ?? '🎯',
                                    style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Ke rekening tabungan',
                                      style: AppTypography.labelSmall
                                          .copyWith(
                                              color: AppColors.textMuted)),
                                  Text(
                                    widget.goal.linkedWalletName ??
                                        'Rekening Tabungan',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _accentColor,
                                    ),
                                  ),
                                  Text(
                                    'Sisa target: ${AppFormatters.currency(remaining.toDouble())}',
                                    style: AppTypography.labelSmall
                                        .copyWith(
                                            color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.lock_rounded,
                                size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick presets
                  Text('Nominal Cepat',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: _presets.map((p) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _applyPreset(p),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color:
                                  _accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _accentColor.withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: Text(
                                p >= 1000000
                                    ? '${p ~/ 1000000}jt'
                                    : '${p ~/ 1000}rb',
                                style: AppTypography.labelSmall.copyWith(
                                  color: _accentColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Amount input
                  Text('Nominal Transfer',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparatorFormatter(),
                    ],
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: AppColors.cardElevated,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: _accentColor, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Balance check warning
                  if (_sourceWallet != null && _parsedAmount > _sourceWallet!.balance)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Saldo ${_sourceWallet!.name} tidak cukup. Tersedia: ${AppFormatters.currency(_sourceWallet!.balance.toDouble())}',
                              style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Note
                  Text('Catatan (opsional)',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Dari gaji bulan ini...',
                      hintStyle: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.cardElevated,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              'Transfer & Nabung',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final digits = newValue.text.replaceAll('.', '');
    final formatted = _format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
