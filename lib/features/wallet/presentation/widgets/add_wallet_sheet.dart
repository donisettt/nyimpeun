import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/app/providers/wallet_providers.dart';
import 'package:nyimpeun/core/theme/app_colors.dart';
import 'package:nyimpeun/core/theme/app_typography.dart';
import 'package:nyimpeun/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';

// Data: Bank Indonesia
const kIndonesianBanks = [
  'BCA (Bank Central Asia)',
  'BNI (Bank Negara Indonesia)',
  'BRI (Bank Rakyat Indonesia)',
  'Bank Mandiri',
  'BSI (Bank Syariah Indonesia)',
  'CIMB Niaga',
  'Bank Danamon',
  'Bank Permata',
  'Bank Mega',
  'Bank OCBC',
  'Bank Panin',
  'Bank BTN',
  'Bank Maybank Indonesia',
  'Bank BTPN',
  'Bank Sinarmas',
  'Bank Bukopin (KB Bank)',
  'Bank Muamalat',
  'Bank Jago',
  'SeaBank',
  'Bank Neo Commerce',
  'Jenius (Bank BTPN)',
  'Blu by BCA Digital',
  'Allo Bank',
  'Bank Raya',
  'Bank Saqu',
  'Krom Bank',
  'Superbank',
  'Digibank (DBS)',
  'Line Bank',
  'Bank BJB',
  'Bank DKI',
  'Bank Jateng',
  'Bank Jatim',
  'Bank Sumut',
  'Lainnya',
];

const kEWallets = [
  'GoPay',
  'OVO',
  'DANA',
  'ShopeePay',
  'LinkAja',
  'Lainnya',
];

/// Opens the AddWalletSheet as a modal bottom sheet.
Future<bool?> showAddWalletSheet(
  BuildContext context, {
  WalletEntity? editEntity,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddWalletSheet(editEntity: editEntity),
  );
}

class AddWalletSheet extends ConsumerStatefulWidget {
  const AddWalletSheet({super.key, this.editEntity});
  final WalletEntity? editEntity;

  @override
  ConsumerState<AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends ConsumerState<AddWalletSheet> {
  final _customNameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  WalletType _selectedType = WalletType.cash;

  // For Bank & E-Wallet: selected from dropdown
  String? _selectedBank;
  String? _selectedEWallet;

  bool _isDefault = false;
  bool _isSubmitting = false;

  static const _typeColors = {
    WalletType.cash: [Color(0xFF059669), Color(0xFF047857)],
    WalletType.bank: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    WalletType.eWallet: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
  };

  static const _typeIcons = {
    WalletType.cash: Icons.account_balance_wallet_rounded,
    WalletType.bank: Icons.account_balance_rounded,
    WalletType.eWallet: Icons.phonelink_rounded,
  };

  @override
  void initState() {
    super.initState();
    if (widget.editEntity != null) {
      final e = widget.editEntity!;
      _selectedType = e.type;
      _isDefault = e.isDefault;

      switch (e.type) {
        case WalletType.bank:
          // name format: "BankName – RekeningName" or just "BankName"
          if (e.name.contains(' – ')) {
            final parts = e.name.split(' – ');
            // Match bank name (case-insensitive prefix match in list)
            final bankName = parts.first.trim();
            _selectedBank = kIndonesianBanks.firstWhere(
              (b) => b.toLowerCase().startsWith(bankName.toLowerCase()),
              orElse: () => bankName,
            );
            _customNameCtrl.text = parts.sublist(1).join(' – ').trim();
          } else {
            _selectedBank = kIndonesianBanks.firstWhere(
              (b) => b.toLowerCase().startsWith(e.name.toLowerCase()),
              orElse: () => e.name,
            );
          }
          break;
        case WalletType.eWallet:
          if (e.name.contains(' – ')) {
            final parts = e.name.split(' – ');
            final ewName = parts.first.trim();
            _selectedEWallet = kEWallets.firstWhere(
              (w) => w.toLowerCase() == ewName.toLowerCase(),
              orElse: () => ewName,
            );
            _customNameCtrl.text = parts.sublist(1).join(' – ').trim();
          } else {
            _selectedEWallet = kEWallets.firstWhere(
              (w) => w.toLowerCase() == e.name.toLowerCase(),
              orElse: () => e.name,
            );
          }
          break;
        case WalletType.cash:
          _customNameCtrl.text = e.name;
          break;
      }
    }
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  int get _parsedBalance {
    final raw = _balanceCtrl.text.replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(raw) ?? 0;
  }

  /// The final wallet name shown on the card preview
  String get _previewTitle {
    switch (_selectedType) {
      case WalletType.bank:
        // e.g. "BANK BCA"
        if (_selectedBank != null) {
          final short = _selectedBank!.split(' (').first;
          return short.toUpperCase();
        }
        return 'Pilih Bank';
      case WalletType.eWallet:
        return _selectedEWallet ?? 'Pilih E-Wallet';
      case WalletType.cash:
        return _customNameCtrl.text.isEmpty
            ? 'Nama Dompet'
            : _customNameCtrl.text;
    }
  }

  /// Subtitle shown below the title on the preview card
  String get _previewSubtitle {
    switch (_selectedType) {
      case WalletType.bank:
        return _customNameCtrl.text.isEmpty
            ? 'Nama Rekening'
            : _customNameCtrl.text;
      case WalletType.eWallet:
        return _customNameCtrl.text.isEmpty ? 'E-Wallet' : _customNameCtrl.text;
      case WalletType.cash:
        return 'Tunai';
    }
  }

  /// The wallet name stored in DB
  String get _walletName {
    switch (_selectedType) {
      case WalletType.bank:
        final bank = _selectedBank?.split(' (').first ?? '';
        final custom = _customNameCtrl.text.trim();
        if (bank.isNotEmpty && custom.isNotEmpty) {
          if (bank.toLowerCase() == custom.toLowerCase()) return bank;
          return '$bank – $custom';
        }
        return bank.isNotEmpty ? bank : custom;
      case WalletType.eWallet:
        final ew = _selectedEWallet ?? '';
        final custom = _customNameCtrl.text.trim();
        if (ew.isNotEmpty && custom.isNotEmpty) {
          if (ew.toLowerCase() == custom.toLowerCase()) return ew;
          return '$ew – $custom';
        }
        return ew.isNotEmpty ? ew : custom;
      case WalletType.cash:
        return _customNameCtrl.text.trim();
    }
  }

  Future<void> _submit() async {
    if (_walletName.isEmpty) {
      _showSnack('Nama dompet tidak boleh kosong');
      return;
    }
    if (_selectedType == WalletType.bank && _selectedBank == null) {
      _showSnack('Pilih bank terlebih dahulu');
      return;
    }
    if (_selectedType == WalletType.eWallet && _selectedEWallet == null) {
      _showSnack('Pilih e-wallet terlebih dahulu');
      return;
    }

    final authState = ref.read(authStateNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    setState(() => _isSubmitting = true);

    final wallet = WalletEntity(
      id: widget.editEntity?.id ?? '',
      userId: authState.user.id,
      name: _walletName,
      type: _selectedType,
      balance: widget.editEntity != null
          ? widget.editEntity!.balance
          : _parsedBalance,
      isDefault: _isDefault,
    );

    try {
      if (widget.editEntity != null) {
        await ref.read(walletRepositoryProvider).updateWallet(wallet);
      } else {
        await ref.read(walletListProvider.notifier).createWallet(wallet);
      }
      await ref
          .read(walletListProvider.notifier)
          .loadWallets(authState.user.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final colors = _typeColors[_selectedType]!;
    final isEdit = widget.editEntity != null;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Dompet' : 'Tambah Dompet',
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
                  const SizedBox(height: 16),

                  //  Preview Card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _typeIcons[_selectedType],
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _previewTitle,
                                style: AppTypography.titleSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_selectedType != WalletType.cash)
                                Text(
                                  _previewSubtitle,
                                  style: AppTypography.labelSmall
                                      .copyWith(color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  //  Jenis Dompet
                  _Label('Jenis Dompet'),
                  const SizedBox(height: 10),
                  Row(
                    children: WalletType.values.map((type) {
                      final isSelected = _selectedType == type;
                      final tc = _typeColors[type]!;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedType = type;
                            _selectedBank = null;
                            _selectedEWallet = null;
                            _customNameCtrl.clear();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                                right: type != WalletType.eWallet ? 8 : 0),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? tc.first
                                  : AppColors.cardElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? tc.first
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _typeIcons[type],
                                  size: 22,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type.label,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  //  Fields berdasarkan tipe─

                  if (_selectedType == WalletType.bank) ...[
                    _Label('Nama Bank'),
                    const SizedBox(height: 8),
                    _SearchableDropdown(
                      key: const ValueKey('bank'),
                      hint: 'Pilih bank...',
                      items: kIndonesianBanks,
                      selected: _selectedBank,
                      onChanged: (v) => setState(() => _selectedBank = v),
                    ),
                    const SizedBox(height: 20),
                    _Label('Nama Rekening'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customNameCtrl,
                      onChanged: (_) => setState(() {}),
                      style: AppTypography.bodyMedium,
                      decoration:
                          _inputDecoration('Contoh: Rekening Gaji, Tabungan'),
                    ),
                  ] else if (_selectedType == WalletType.eWallet) ...[
                    _Label('E-Wallet'),
                    const SizedBox(height: 8),
                    _SearchableDropdown(
                      key: const ValueKey('ewallet'),
                      hint: 'Pilih e-wallet...',
                      items: kEWallets,
                      selected: _selectedEWallet,
                      onChanged: (v) => setState(() => _selectedEWallet = v),
                    ),
                    const SizedBox(height: 20),
                    _Label('Label (opsional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customNameCtrl,
                      onChanged: (_) => setState(() {}),
                      style: AppTypography.bodyMedium,
                      decoration:
                          _inputDecoration('Contoh: Belanja, Darurat'),
                    ),
                  ] else ...[
                    _Label('Nama Dompet'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customNameCtrl,
                      onChanged: (_) => setState(() {}),
                      style: AppTypography.bodyMedium,
                      decoration: _inputDecoration(
                          'Contoh: Dompet Utama, Kas Harian'),
                    ),
                  ],

                  //  Saldo Awal (only create)
                  if (!isEdit) ...[
                    const SizedBox(height: 20),
                    _Label('Saldo Awal'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _balanceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ThousandsSeparatorFormatter(),
                      ],
                      style: AppTypography.bodyMedium,
                      decoration: _inputDecoration('0').copyWith(
                        prefixText: 'Rp ',
                        prefixStyle: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  //  Jadikan Utama
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jadikan Dompet Utama',
                                style: AppTypography.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Digunakan sebagai dompet default transaksi',
                                style: AppTypography.labelSmall
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isDefault,
                          onChanged: (v) =>
                              setState(() => _isDefault = v),
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primaryContainer,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  //  Submit
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _typeColors[_selectedType]!.first,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                              isEdit ? 'Simpan Perubahan' : 'Tambah Dompet',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.cardElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// Searchable Dropdown

class _SearchableDropdown extends StatefulWidget {
  const _SearchableDropdown({
    super.key,
    required this.hint,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final String hint;
  final List<String> items;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  State<_SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<_SearchableDropdown> {
  bool _open = false;
  final _searchCtrl = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = widget.items
            .where((i) => i.toLowerCase().contains(q))
            .toList();
      });
    });
  }

  @override
  void didUpdateWidget(_SearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset list when the items source changes (e.g. bank ↔ e-wallet)
    if (oldWidget.items != widget.items) {
      _searchCtrl.clear();
      _filtered = widget.items;
      _open = false;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Trigger
        GestureDetector(
          onTap: () => setState(() {
            _open = !_open;
            if (!_open) _searchCtrl.clear();
          }),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardElevated,
              borderRadius:
                  BorderRadius.circular(_open ? 14 : 14),
              border: Border.all(
                color: _open ? AppColors.primary : AppColors.border,
                width: _open ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.selected ?? widget.hint,
                    style: AppTypography.bodyMedium.copyWith(
                      color: widget.selected != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _open ? 0.5 : 0,
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),

        // Dropdown list
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _searchCtrl,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Cari...',
                      hintStyle: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.cardElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                // List
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final item = _filtered[i];
                      final isSelected = widget.selected == item;
                      return InkWell(
                        onTap: () {
                          widget.onChanged(item);
                          setState(() {
                            _open = false;
                            _searchCtrl.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          color: isSelected
                              ? AppColors.primaryContainer
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_rounded,
                                    size: 18, color: AppColors.primary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: _open
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),
      ],
    );
  }
}

// Helpers

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelLarge.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
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
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
