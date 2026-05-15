import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/core/widgets/loading_skeleton.dart';
import 'package:zeno/features/auth/presentation/providers/auth_providers.dart';
import 'package:zeno/features/library/domain/deck.dart';
import 'package:zeno/features/library/presentation/providers/deck_providers.dart';
import 'package:zeno/features/library/presentation/widgets/deck_card.dart';
import 'package:zeno/features/review/presentation/providers/review_providers.dart';
import 'package:zeno/features/user/domain/user_stats.dart';
import 'package:zeno/features/user/presentation/providers/user_stats_providers.dart';

/// Home tab — surfaces streak, cards due today, and recent decks.
class HomeScreen extends ConsumerWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ------------------------------------------------------------------
          // 1. Streak card
          // ------------------------------------------------------------------
          ref.watch(userStatsProvider).when(
                data: (stats) => _StreakCard(stats: stats),
                loading: () => const LoadingSkeleton(height: 120),
                error: (_, __) => const SizedBox.shrink(),
              ),

          const SizedBox(height: 16),

          // ------------------------------------------------------------------
          // 2. Due today
          // ------------------------------------------------------------------
          ref.watch(dueCardsAllProvider).when(
                data: (cards) => _DueTodayCard(dueCount: cards.length),
                loading: () => const LoadingSkeleton(height: 72),
                error: (_, __) => const SizedBox.shrink(),
              ),

          const SizedBox(height: 16),

          // ------------------------------------------------------------------
          // 3. Recent decks
          // ------------------------------------------------------------------
          Text('Decks gần đây', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          ref.watch(deckListProvider).when(
                data: (decks) => _RecentDecks(decks: decks),
                loading: () => Column(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LoadingSkeleton(height: 88),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/library'),
              child: const Text('Xem tất cả →'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Streak card widget
// ---------------------------------------------------------------------------
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 8),
                Text(
                  '${stats.streak}',
                  style: textTheme.headlineLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'ngày streak',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Best: ${stats.bestStreak}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Due today card widget
// ---------------------------------------------------------------------------
class _DueTodayCard extends StatelessWidget {
  const _DueTodayCard({required this.dueCount});

  final int dueCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/review'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dueCount == 0
                      ? 'Không có card đến hạn hôm nay 🎉'
                      : '$dueCount card đến hạn',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (dueCount > 0)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent decks list widget
// ---------------------------------------------------------------------------
class _RecentDecks extends StatelessWidget {
  const _RecentDecks({required this.decks});

  final List<Deck> decks;

  @override
  Widget build(BuildContext context) {
    if (decks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Chưa có deck nào. Hãy tạo deck đầu tiên!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    // Sort by updatedAt descending, take top 3
    final sorted = [...decks]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recent = sorted.take(3).toList();

    return Column(
      children: recent
          .map(
            (deck) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DeckCard(
                deck: deck,
                onTap: () => context.push('/decks/${deck.id}'),
              ),
            ),
          )
          .toList(),
    );
  }
}
