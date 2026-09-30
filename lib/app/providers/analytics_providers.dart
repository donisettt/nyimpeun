import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/providers/wallet_providers.dart';
import 'package:nyimpeun/features/analytics/presentation/viewmodels/analytics_viewmodel.dart';

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(
    repository: ref.watch(walletRepositoryProvider),
  );
});
