import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/app/router/app_router.dart';
import 'package:nyimpeun/app/widgets/global_network_wrapper.dart';
import 'package:nyimpeun/core/theme/app_theme.dart';

class NyimpeunApp extends ConsumerWidget {
  const NyimpeunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Nyimpeun - Aplikasi Pelacak Keuanganmu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        return GlobalNetworkWrapper(
          router: router,
          child: child!,
        );
      },
    );
  }
}
