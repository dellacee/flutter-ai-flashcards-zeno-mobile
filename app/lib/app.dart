import 'package:flutter/material.dart';
import 'package:zeno/core/theme/app_theme.dart';

/// Root widget of the Zeno application.
///
/// Sets up Material 3 theming and the initial screen. Routing, providers
/// and feature screens are wired in later foundation tasks.
class ZenoApp extends StatelessWidget {
  /// Creates the root [ZenoApp] widget.
  const ZenoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zeno',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const _BootstrapPlaceholder(),
    );
  }
}

class _BootstrapPlaceholder extends StatelessWidget {
  const _BootstrapPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Zeno', style: theme.textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(
              'Foundation ready',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
