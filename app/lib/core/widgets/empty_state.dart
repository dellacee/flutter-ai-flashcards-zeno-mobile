import 'package:flutter/material.dart';

/// A centered empty-state widget showing an icon, title, description,
/// and an optional action widget (e.g. a button to create content).
class EmptyState extends StatelessWidget {
  /// Creates an [EmptyState].
  const EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    super.key,
  });

  /// Icon displayed at the top, at 56 dp in the primary color.
  final IconData icon;

  /// Short headline summarising the empty state.
  final String title;

  /// Longer descriptive text explaining what the user can do next.
  final String description;

  /// Optional action widget (e.g. a [FilledButton]) shown below the
  /// description.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
