import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/core/widgets/main_scaffold.dart';
import 'package:zeno/features/home/presentation/home_screen.dart';
import 'package:zeno/features/library/presentation/library_screen.dart';
import 'package:zeno/features/review/presentation/review_screen.dart';

/// Manual [Provider] exposing the app's [GoRouter] configuration.
///
/// Auth redirect is intentionally absent — it will be wired in Task 2.5 once
/// the auth-state provider exists.  Riverpod codegen is deferred to V1.1 per
/// commit 263ff07.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/review',
                builder: (context, state) => const ReviewScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
