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
import 'package:nyimpeun/features/wallet/presentation/widgets/manage_categories_sheet.dart';
import 'package:nyimpeun/core/utils/formatters.dart';
import 'package:nyimpeun/app/providers/savings_providers.dart';
import 'package:nyimpeun/features/savings/presentation/viewmodels/savings_viewmodel.dart';
import 'package:nyimpeun/features/wallet/l10n/wallet_l10n.dart';
import 'package:nyimpeun/core/l10n/language_provider.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key, this.initialType = 'expense', this.editEntity});

  final String initialType; // 'income' or 'expense'
  final TransactionEntity? editEntity;

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  late String _type;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  CategoryEntity? _selectedCategory;
  WalletEntity? _selectedWallet;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.editEntity?.type.value ?? widget.initialType;

    if (widget.editEntity != null) {
      final e = widget.editEntity!;
      _amountCtrl.text = AppFormatters.inputCurrency(e.amount.toString());
      _noteCtrl.text = e.note ?? '';
      _selectedDate = e.date;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final authState = ref.read(authStateNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    final userId = authState.user.id;

    ref.read(categoryProvider.notifier).loadCategories(userId);
    ref.read(walletListProvider.notifier).loadWallets(userId);
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _showCategoryPicker(List<CategoryEntity> categories, WalletL10n l10n) async {
    final cat = await showModalBottomSheet<CategoryEntity>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.pickCategory,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded, color: AppColors.primary),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openManageCategories();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (categories.isEmpty)
                 Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noCategory),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final c = categories[index];
                      return ListTile(
                        leading: _buildCategoryIcon(c),
                        title: Text(c.name, style: AppTypography.bodyMedium),
                        onTap: () => Navigator.pop(ctx, c),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (cat != null) setState(() => _selectedCategory = cat);
  }

  Future<void> _showWalletPicker(List<WalletEntity> wallets, WalletL10n l10n) async {
    final w = await showModalBottomSheet<WalletEntity>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.wallet,
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              if (wallets.isEmpty)
                 Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noWallet),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: wallets.length,
                    itemBuilder: (context, index) {
                      final wItem = wallets[index];
                      return ListTile(
                        leading: Icon(
                          wItem.type == WalletType.cash
                              ? Icons.account_balance_wallet_rounded
                              : wItem.type == WalletType.bank
                                  ? Icons.account_balance_rounded
                                  : Icons.phonelink_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(wItem.name, style: AppTypography.bodyMedium),
                        subtitle: Text(AppFormatters.currency(wItem.balance.toDouble())),
                        onTap: () => Navigator.pop(ctx, wItem),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (w != null) setState(() => _selectedWallet = w);
  }

  void _openManageCategories() async {
    final authState = ref.read(authStateNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    await showManageCategoriesSheet(
      context,
      userId: authState.user.id,
      type: _type,
    );
    ref.read(categoryProvider.notifier).loadCategories(authState.user.id);
  }

  Future<void> _submit(WalletL10n l10n) async {
    if (_parsedAmount <= 0) {
      _showSnack(l10n.invalidAmount);
      return;
    }
    if (_selectedCategory == null && widget.editEntity?.categoryId == null) {
      _showSnack(l10n.selectCategoryFirst);
      return;
    }

    final authState = ref.read(authStateNotifierProvider);
    if (authState is! AuthAuthenticated) return;

    final wallets = ref.read(walletListProvider).wallets;
    final wallet = _selectedWallet ?? (widget.editEntity != null ? wallets.firstWhere((w) => w.id == widget.editEntity!.walletId, orElse: () => wallets.first) : (wallets.isNotEmpty ? wallets.first : null));
    
    if (wallet == null) {
      _showSnack(l10n.selectWallet);
      return;
    }

    setState(() => _isSubmitting = true);

    final tx = TransactionEntity(
      id: widget.editEntity?.id ?? '',
      userId: authState.user.id,
      walletId: wallet.id,
      walletName: wallet.name,
      categoryId: _selectedCategory?.id ?? widget.editEntity?.categoryId,
      categoryName: _selectedCategory?.name ?? widget.editEntity?.categoryName,
      categoryColor: _selectedCategory?.color ?? widget.editEntity?.categoryColor,
      type: TransactionType.fromString(_type),
      amount: _parsedAmount,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      date: _selectedDate,
    );

    try {
      if (widget.editEntity != null) {
        await ref.read(walletRepositoryProvider).updateTransaction(tx);
        await ref.read(transactionListProvider.notifier).loadTransactions(
          userId: authState.user.id,
          walletId: ref.read(walletListProvider).selectedWalletId,
        );
      } else {
        await ref.read(transactionListProvider.notifier).addTransaction(tx);
        // Untuk pemasukan: cek apakah ada goal auto-alokasi aktif
        if (_type == 'income') {
          ref.read(savingsProvider.notifier).buildAutoAllocateRecommendations(
            userId: authState.user.id,
            incomeAmount: _parsedAmount,
          );
          // Tampilkan dialog setelah pop halaman ini
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showAutoAllocateRecommendation(authState.user.id);
          });
        }
      }

      // Reload wallet agar balance terupdate dari trigger Supabase
      await ref.read(walletListProvider.notifier).loadWallets(authState.user.id);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Dialog rekomendasi alokasi tabungan — muncul setelah income disimpan
  void _showAutoAllocateRecommendation(String userId) {
    final allocations = ref.read(savingsProvider).pendingAllocations;
    if (allocations.isEmpty) return;

    // Cari wallet utama (default source)
    final wallets = ref.read(walletListProvider).wallets;
    final defaultWallet =
        wallets.where((w) => w.isDefault).firstOrNull ?? wallets.firstOrNull;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: _AutoAllocateDialog(
          allocations: allocations,
          userId: userId,
          defaultSourceWallet: defaultWallet,
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(CategoryEntity c) {
    String path = 'assets/images/wallet/lainnya.webp';
    final lower = c.name.toLowerCase();
    if (lower.contains('belanja')) path = 'assets/images/wallet/belanja.webp';
    else if (lower.contains('bonus')) path = 'assets/images/wallet/bonus.webp';
    else if (lower.contains('gaji')) path = 'assets/images/wallet/gaji.webp';
    else if (lower.contains('hiburan')) path = 'assets/images/wallet/hiburan.webp';
    else if (lower.contains('investasi')) path = 'assets/images/wallet/investasi.webp';
    else if (lower.contains('kesehatan')) path = 'assets/images/wallet/kesehatan.webp';
    else if (lower.contains('makanan') || lower.contains('makan')) path = 'assets/images/wallet/makanan.webp';
    else if (lower.contains('tagihan')) path = 'assets/images/wallet/tagihan.webp';
    else if (lower.contains('transport')) path = 'assets/images/wallet/transport.webp';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(path, width: 32, height: 32, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catState = ref.watch(categoryProvider);
    final walletState = ref.watch(walletListProvider);
    final l10n = WalletL10n.of(ref.watch(languageProvider));

    final categories = _type == 'income' ? catState.incomeCategories : catState.expenseCategories;
    final formatter = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

    final catName = _selectedCategory?.name ?? widget.editEntity?.categoryName ?? l10n.selectCategory;
    
    // Fallback wallet if not selected
    final wFallback = walletState.selectedWallet ?? (walletState.wallets.isNotEmpty ? walletState.wallets.first : null);
    final walletName = _selectedWallet?.name ?? widget.editEntity?.walletName ?? wFallback?.name ?? l10n.selectWallet;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editEntity != null ? l10n.editTransaction : l10n.newTransaction,
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          _buildTab(l10n.incomeType, 'income'),
                          _buildTab(l10n.expenseType, 'expense'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amount
                    _SectionLabel(l10n.amount),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ThousandsSeparatorFormatter(),
                      ],
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        suffixIcon: const Icon(Icons.money_rounded, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category
                    _SectionLabel(l10n.category),
                    const SizedBox(height: 8),
                    _buildSelectionField(
                      text: catName,
                      icon: Icons.chevron_right_rounded,
                      onTap: () => _showCategoryPicker(categories, l10n),
                    ),
                    const SizedBox(height: 20),

                    // Date
                    _SectionLabel(l10n.date),
                    const SizedBox(height: 8),
                    _buildSelectionField(
                      text: formatter.format(_selectedDate),
                      icon: Icons.calendar_today_rounded,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 20),

                    // Note
                    _SectionLabel(l10n.note),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: l10n.noteHint,
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Wallet
                    _SectionLabel(l10n.wallet),
                    const SizedBox(height: 8),
                    _buildSelectionField(
                      text: walletName,
                      icon: Icons.chevron_right_rounded,
                      onTap: () => _showWalletPicker(walletState.wallets, l10n),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Bottom Save Button
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submit(l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          widget.editEntity != null ? l10n.saveChanges : l10n.save,
                          style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, String type) {
    final isActive = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _selectedCategory = null; // reset category on type change
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelLarge.copyWith(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionField({required String text, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(icon, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
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

// ─── Auto-Allocate Recommendation Dialog ──────────────────────────────────────

class _AutoAllocateDialog extends ConsumerStatefulWidget {
  const _AutoAllocateDialog({
    required this.allocations,
    required this.userId,
    required this.defaultSourceWallet,
  });

  final List<SavingsPendingAllocation> allocations;
  final String userId;
  final dynamic defaultSourceWallet; // WalletEntity?

  @override
  ConsumerState<_AutoAllocateDialog> createState() =>
      _AutoAllocateDialogState();
}

class _AutoAllocateDialogState extends ConsumerState<_AutoAllocateDialog> {
  late final Map<String, bool> _checked;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checked = {for (final a in widget.allocations) a.goal.id: true};
  }

  int get _totalAllocated => widget.allocations
      .where((a) => _checked[a.goal.id] == true)
      .fold(0, (sum, a) => sum + a.recommendedAmount);

  Future<void> _confirmAllocations() async {
    if (widget.defaultSourceWallet == null) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isProcessing = true);

    for (final alloc in widget.allocations) {
      if (_checked[alloc.goal.id] != true) continue;
      if (alloc.goal.linkedWalletId == null) continue;

      await ref.read(savingsProvider.notifier).contribute(
            goal: alloc.goal,
            userId: widget.userId,
            amount: alloc.recommendedAmount,
            note: 'Alokasi otomatis dari pemasukan',
            sourceWalletId: widget.defaultSourceWallet.id as String,
            sourceWalletName: widget.defaultSourceWallet.name as String,
          );
    }

    ref.read(savingsProvider.notifier).clearPendingAllocations();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clean, native-looking header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.savings_rounded, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'Alokasi Tabungan',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sebagian pemasukan ini bisa langsung dialokasikan ke tabungan sesuai aturan yang kamu buat.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: AppColors.border),
          
          // Clean list of allocations
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.allocations.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border, indent: 24, endIndent: 24),
              itemBuilder: (ctx, i) {
                final alloc = widget.allocations[i];
                final isChecked = _checked[alloc.goal.id] ?? false;
                return InkWell(
                  onTap: () => setState(() => _checked[alloc.goal.id] = !isChecked),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isChecked,
                            onChanged: (v) => setState(() => _checked[alloc.goal.id] = v ?? false),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${alloc.goal.icon ?? '🎯'}  ${alloc.goal.name}',
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (alloc.goal.linkedWalletName != null)
                                Text(
                                  'Ke: ${alloc.goal.linkedWalletName}',
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          AppFormatters.currency(alloc.recommendedAmount.toDouble()),
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700, 
                            color: isChecked ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Divider(height: 1, color: AppColors.border),
          
          // Summary & Actions Footer
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (widget.defaultSourceWallet != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sumber Dana', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                      Expanded(
                        child: Text(
                          widget.defaultSourceWallet.name,
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Alokasi', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      AppFormatters.currency(_totalAllocated.toDouble()),
                      style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          ref.read(savingsProvider.notifier).clearPendingAllocations();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Lewati', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isProcessing || _totalAllocated == 0 ? null : _confirmAllocations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('Alokasikan', style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
