import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';
import 'package:nyimpeun/features/wallet/domain/repositories/wallet_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class WalletListState {
  const WalletListState({
    this.wallets = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedWalletId,
  });

  final List<WalletEntity> wallets;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedWalletId;

  WalletEntity? get selectedWallet {
    if (wallets.isEmpty) return null;
    if (selectedWalletId == null) return wallets.first;
    return wallets.firstWhere(
      (w) => w.id == selectedWalletId,
      orElse: () => wallets.first,
    );
  }

  int get totalBalance => wallets.fold(0, (sum, w) => sum + w.balance);

  WalletListState copyWith({
    List<WalletEntity>? wallets,
    bool? isLoading,
    String? errorMessage,
    String? selectedWalletId,
    bool clearError = false,
  }) {
    return WalletListState(
      wallets: wallets ?? this.wallets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedWalletId: selectedWalletId ?? this.selectedWalletId,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class WalletListNotifier extends StateNotifier<WalletListState> {
  WalletListNotifier({required this._repository})
      : super(const WalletListState());

  final WalletRepository _repository;

  Future<void> loadWallets(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final wallets = await _repository.getWallets(userId);
      final defaultId = wallets.where((w) => w.isDefault).firstOrNull?.id ??
          (wallets.isNotEmpty ? wallets.first.id : null);
      state = state.copyWith(
        wallets: wallets,
        isLoading: false,
        selectedWalletId: state.selectedWalletId ?? defaultId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectWallet(String walletId) {
    state = state.copyWith(selectedWalletId: walletId);
  }

  Future<void> createWallet(WalletEntity wallet) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _repository.createWallet(wallet);
      state = state.copyWith(
        wallets: [...state.wallets, created],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> deleteWallet(String walletId) async {
    final prev = state.wallets;
    state = state.copyWith(
      wallets: prev.where((w) => w.id != walletId).toList(),
    );
    try {
      await _repository.deleteWallet(walletId);
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(wallets: prev, errorMessage: e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
