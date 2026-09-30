import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:nyimpeun/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:nyimpeun/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:nyimpeun/features/wallet/presentation/viewmodels/category_viewmodel.dart';
import 'package:nyimpeun/features/wallet/presentation/viewmodels/transaction_list_viewmodel.dart';
import 'package:nyimpeun/features/wallet/presentation/viewmodels/wallet_list_viewmodel.dart';

// ─── Data Layer ───────────────────────────────────────────────────────────────

final walletRemoteDatasourceProvider = Provider<WalletRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return WalletRemoteDataSource(dio: dio);
});

// ─── Repository ───────────────────────────────────────────────────────────────

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(
    remoteDataSource: ref.watch(walletRemoteDatasourceProvider),
  );
});

// ─── Presentation ─────────────────────────────────────────────────────────────

final walletListProvider =
    StateNotifierProvider<WalletListNotifier, WalletListState>((ref) {
  return WalletListNotifier(
    repository: ref.watch(walletRepositoryProvider),
  );
});

final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
  return TransactionListNotifier(
    repository: ref.watch(walletRepositoryProvider),
  );
});

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(
    repository: ref.watch(walletRepositoryProvider),
  );
});
