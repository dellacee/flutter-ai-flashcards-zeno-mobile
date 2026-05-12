import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/core/routing/app_router.dart';
import 'package:zeno/core/theme/app_theme.dart';

/// Root widget of the Zeno application.
///
/// Reads [appRouterProvider] to configure [MaterialApp.router] with GoRouter,
/// Material 3 theming, and support for system-level dark mode.
class ZenoApp extends ConsumerWidget {
  /// Creates the root [ZenoApp] widget.
  const ZenoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Zeno',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
