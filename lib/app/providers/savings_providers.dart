import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/providers/app_providers.dart';
import 'package:nyimpeun/app/providers/wallet_providers.dart';
import 'package:nyimpeun/features/savings/data/datasources/savings_remote_datasource.dart';
import 'package:nyimpeun/features/savings/data/repositories/savings_repository_impl.dart';
import 'package:nyimpeun/features/savings/domain/repositories/savings_repository.dart';
import 'package:nyimpeun/features/savings/presentation/viewmodels/savings_viewmodel.dart';

// ─── Data Layer ───────────────────────────────────────────────────────────────

final savingsRemoteDatasourceProvider =
    Provider<SavingsRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return SavingsRemoteDataSource(dio: dio);
});

// ─── Repository ───────────────────────────────────────────────────────────────

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  return SavingsRepositoryImpl(
    remoteDataSource: ref.watch(savingsRemoteDatasourceProvider),
  );
});

// ─── Presentation ─────────────────────────────────────────────────────────────

final savingsProvider =
    StateNotifierProvider<SavingsNotifier, SavingsState>((ref) {
  return SavingsNotifier(
    repository: ref.watch(savingsRepositoryProvider),
    walletRepository: ref.watch(walletRepositoryProvider),
  );
});
