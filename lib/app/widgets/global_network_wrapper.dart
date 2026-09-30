import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:nyimpeun/features/dashboard/presentation/widgets/no_internet_sheet.dart';
import 'package:nyimpeun/app/router/app_router.dart';

class GlobalNetworkWrapper extends StatefulWidget {
  final Widget child;
  final GoRouter router;

  const GlobalNetworkWrapper({
    super.key,
    required this.child,
    required this.router,
  });

  @override
  State<GlobalNetworkWrapper> createState() => _GlobalNetworkWrapperState();
}

class _GlobalNetworkWrapperState extends State<GlobalNetworkWrapper> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen(_handleConnectivity);
    _checkInitial();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    _handleConnectivity(results);
  }

  void _handleConnectivity(List<ConnectivityResult> results) {
    final hasInternet = results.any((r) => r != ConnectivityResult.none);
    
    // Check current route
    final currentPath = widget.router.routerDelegate.currentConfiguration.uri.path;
    
    // Do not show on onboarding or splash
    final isExcluded = currentPath == AppRoutes.onboarding || currentPath == AppRoutes.loading;

    if (!hasInternet && !_isShowing && !isExcluded) {
      _isShowing = true;
      final context = widget.router.routerDelegate.navigatorKey.currentContext;
      if (context != null) {
        showNoInternetSheet(context);
      }
    } else if (hasInternet && _isShowing) {
      _isShowing = false;
      final context = widget.router.routerDelegate.navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
