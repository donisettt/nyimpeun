import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/providers/wallet_providers.dart';
import 'package:nyimpeun/features/dashboard/presentation/viewmodels/dashboard_spending_viewmodel.dart';

final dashboardSpendingProvider =
    StateNotifierProvider<DashboardSpendingNotifier, DashboardSpendingState>((ref) {
  return DashboardSpendingNotifier(
    repository: ref.watch(walletRepositoryProvider),
  );
});
