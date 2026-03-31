import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import '../core/theme/app_theme.dart';
import '../services/billing_service/billing_service.dart';
import '../core/theme/theme_provider.dart';

/// Root application widget.
class ScaleFinderApp extends ConsumerWidget {
  const ScaleFinderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    
    // Initialize billing service globally to catch pending purchases
    ref.watch(billingProvider);

    return MaterialApp.router(
      title: 'Scale Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
