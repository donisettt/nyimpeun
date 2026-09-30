import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyimpeun/app/providers/savings_providers.dart';
import 'package:nyimpeun/app/providers/wallet_providers.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/core/utils/formatters.dart';
import 'package:nyimpeun/features/savings/domain/entities/savings_goal_entity.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';

// ─── Preset Data ──────────────────────────────────────────────────────────────

const _kPresetIcons = [
  '🎯', '🏖️', '🏠', '🚗', '💍', '🎓', '💻', '✈️',
  '🏥', '🎁', '🐣', '💰', '📱', '🍜', '🎮', '⚽',
];

const _kPresetColors = [
  '#2563EB', '#7C3AED', '#059669', '#DC2626',
  '#D97706', '#0EA5E9', '#DB2777', '#65A30D',
];

// ─── Helper ───────────────────────────────────────────────────────────────────

Future<bool?> showAddSavingsGoalSheet(
  BuildContext context, {
  SavingsGoalEntity? editGoal,
  required String userId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddSavingsGoalSheet(editGoal: editGoal, userId: userId),
  );
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class AddSavingsGoalSheet extends ConsumerStatefulWidget {
  const AddSavingsGoalSheet({
    super.key,
    this.editGoal,
    required this.userId,
  });

  final SavingsGoalEntity? editGoal;
  final String userId;

  @override
  ConsumerState<AddSavingsGoalSheet> createState() =>
      _AddSavingsGoalSheetState();
}

class _AddSavingsGoalSheetState extends ConsumerState<AddSavingsGoalSheet> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();

  String _selectedIcon = '🎯';
  String _selectedColor = '#2563EB';
  DateTime? _deadline;
  int _autoPercent = 0;
  bool _isSubmitting = false;
  WalletEntity? _linkedWallet; // Rekening tujuan tabungan

  @override
  void initState() {
    super.initState();
    if (widget.editGoal != null) {
      final g = widget.editGoal!;
      _nameCtrl.text = g.name;
      _targetCtrl.text = AppFormatters.inputCurrency(g.targetAmount.toString());
      _selectedIcon = g.icon ?? '🎯';
      _selectedColor = g.color ?? '#2563EB';
      _deadline = g.deadline;
      _autoPercent = g.autoAllocatePercent;
      // Try to find linked wallet from state
      if (g.linkedWalletId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final wallets = ref.read(walletListProvider).wallets;
          final found = wallets.where((w) => w.id == g.linkedWalletId).firstOrNull;
          if (found != null && mounted) setState(() => _linkedWallet = found);
        });
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  int get _parsedTarget {
    final raw = _targetCtrl.text.replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(raw) ?? 0;
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickLinkedWallet() async {
    final wallets = ref.read(walletListProvider).wallets;
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambah dompet tabungan terlebih dahulu di halaman Dompet'),
        ),
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
                Text('Pilih Rekening Tabungan',
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Dana tabungan akan dicatat masuk ke rekening ini',
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
                final isSelected = _linkedWallet?.id == w.id;
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
                  subtitle: Text(AppFormatters.currency(w.balance.toDouble()),
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textMuted)),
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

    if (selected != null) setState(() => _linkedWallet = selected);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Masukkan nama tabungan');
      return;
    }
    if (_parsedTarget <= 0) {
      _showSnack('Masukkan target nominal yang valid');
      return;
    }
    if (_linkedWallet == null) {
      _showSnack('Pilih rekening yang akan digunakan untuk menyimpan tabungan ini');
      return;
    }

    setState(() => _isSubmitting = true);

    final goal = SavingsGoalEntity(
      id: widget.editGoal?.id ?? '',
      userId: widget.userId,
      name: _nameCtrl.text.trim(),
      targetAmount: _parsedTarget,
      currentAmount: widget.editGoal?.currentAmount ?? 0,
      linkedWalletId: _linkedWallet!.id,
      linkedWalletName: _linkedWallet!.name,
      deadline: _deadline,
      icon: _selectedIcon,
      color: _selectedColor,
      status: widget.editGoal?.status ?? 'active',
      autoAllocatePercent: _autoPercent,
    );

    bool success;
    if (widget.editGoal != null) {
      success = await ref.read(savingsProvider.notifier).updateGoal(goal);
    } else {
      success = await ref.read(savingsProvider.notifier).createGoal(goal);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        _showSnack(ref.read(savingsProvider).errorMessage ?? 'Terjadi kesalahan');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Color get _accentColor {
    try {
      return Color(
          int.parse('FF${_selectedColor.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final dateFormatter = DateFormat('d MMMM yyyy', 'id_ID');

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
                      Text(
                        widget.editGoal != null
                            ? 'Edit Tabungan'
                            : 'Tabungan Baru',
                        style: AppTypography.titleLarge
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Icon & Color picker
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _accentColor, width: 2),
                        ),
                        child: Center(
                          child: Text(_selectedIcon,
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Icon',
                                style: AppTypography.labelSmall
                                    .copyWith(color: AppColors.textMuted)),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 36,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _kPresetIcons.length,
                                itemBuilder: (context, i) {
                                  final icon = _kPresetIcons[i];
                                  final sel = icon == _selectedIcon;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedIcon = icon),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? _accentColor.withValues(alpha: 0.15)
                                            : AppColors.cardElevated,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: sel
                                                ? _accentColor
                                                : Colors.transparent),
                                      ),
                                      child: Center(
                                        child: Text(icon,
                                            style: const TextStyle(fontSize: 18)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Color row
                  Text('Warna',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Row(
                    children: _kPresetColors.map((hex) {
                      Color c;
                      try {
                        c = Color(int.parse(
                            'FF${hex.replaceAll('#', '')}', radix: 16));
                      } catch (_) {
                        c = AppColors.primary;
                      }
                      final sel = hex == _selectedColor;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColor = hex),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  sel ? Colors.black54 : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: sel
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Name
                  _SectionLabel('Nama Tabungan'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: AppTypography.bodyMedium,
                    decoration:
                        _inputDeco('Contoh: Dana Darurat, Liburan Bali'),
                  ),
                  const SizedBox(height: 16),

                  // Target
                  _SectionLabel('Target Nominal'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _targetCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparatorFormatter(),
                    ],
                    style: AppTypography.bodyMedium,
                    decoration:
                        _inputDeco('0').copyWith(prefixText: 'Rp '),
                  ),
                  const SizedBox(height: 16),

                  // ── Linked Wallet (WAJIB) ──────────────────────────────
                  Row(
                    children: [
                      _SectionLabel('Rekening Tabungan'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Wajib',
                            style: AppTypography.labelSmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih rekening/dompet khusus yang kamu gunakan untuk menyimpan uang tabungan ini.',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickLinkedWallet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _linkedWallet != null
                            ? _accentColor.withValues(alpha: 0.06)
                            : AppColors.cardElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _linkedWallet != null
                              ? _accentColor
                              : AppColors.border,
                          width: _linkedWallet != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _linkedWallet != null
                                ? (_linkedWallet!.type == WalletType.cash
                                    ? Icons.account_balance_wallet_rounded
                                    : _linkedWallet!.type == WalletType.bank
                                        ? Icons.account_balance_rounded
                                        : Icons.phonelink_rounded)
                                : Icons.account_balance_rounded,
                            color: _linkedWallet != null
                                ? _accentColor
                                : AppColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _linkedWallet?.name ??
                                      'Pilih rekening tabungan...',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: _linkedWallet != null
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                    fontWeight: _linkedWallet != null
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                                if (_linkedWallet != null)
                                  Text(
                                    AppFormatters.currency(
                                        _linkedWallet!.balance.toDouble()),
                                    style: AppTypography.labelSmall
                                        .copyWith(color: AppColors.textMuted),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: _linkedWallet != null
                                  ? _accentColor
                                  : AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Deadline
                  _SectionLabel('Deadline (opsional)'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDeadline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _deadline != null
                                  ? dateFormatter.format(_deadline!)
                                  : 'Pilih tanggal target...',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _deadline != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                          if (_deadline != null)
                            GestureDetector(
                              onTap: () => setState(() => _deadline = null),
                              child: const Icon(Icons.clear_rounded,
                                  size: 18, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Auto-allocate slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel('Rekomendasi dari Pemasukan'),
                      Text(
                        _autoPercent == 0 ? 'Tidak aktif' : '$_autoPercent%',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _autoPercent == 0
                              ? AppColors.textMuted
                              : _accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _autoPercent == 0
                        ? 'Aktifkan untuk mendapat pengingat alokasi setiap ada pemasukan baru.'
                        : 'Setiap ada pemasukan, Nyimpeun akan mengingatkan untuk mengalokasikan $_autoPercent% ke tabungan ini.',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                  Slider(
                    value: _autoPercent.toDouble(),
                    min: 0,
                    max: 50,
                    divisions: 50,
                    activeColor: _accentColor,
                    inactiveColor: _accentColor.withValues(alpha: 0.2),
                    label: _autoPercent == 0 ? 'Nonaktif' : '$_autoPercent%',
                    onChanged: (v) =>
                        setState(() => _autoPercent = v.round()),
                  ),
                  const SizedBox(height: 28),

                  // Submit
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
                              widget.editGoal != null
                                  ? 'Simpan Perubahan'
                                  : 'Buat Tabungan',
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

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.cardElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
          AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
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
