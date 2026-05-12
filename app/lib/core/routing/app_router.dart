import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/core/widgets/main_scaffold.dart';
import 'package:zeno/features/auth/domain/auth_user.dart';
import 'package:zeno/features/auth/presentation/providers/auth_providers.dart';
import 'package:zeno/features/auth/presentation/sign_in_screen.dart';
import 'package:zeno/features/cards/presentation/add_card_screen.dart';
import 'package:zeno/features/cards/presentation/edit_card_screen.dart';
import 'package:zeno/features/home/presentation/home_screen.dart';
import 'package:zeno/features/library/presentation/create_deck_screen.dart';
import 'package:zeno/features/library/presentation/deck_detail_screen.dart';
import 'package:zeno/features/library/presentation/edit_deck_screen.dart';
import 'package:zeno/features/library/presentation/library_screen.dart';
import 'package:zeno/features/review/presentation/review_screen.dart';

/// Manual [Provider] exposing the app's [GoRouter] configuration.
///
/// Auth redirect is driven by [_AuthRefreshNotifier], a small
/// [ChangeNotifier] that calls [ChangeNotifier.notifyListeners]
/// whenever [authStateChangesProvider] emits a new value. GoRouter
/// re-runs the redirect callback on every notification, routing
/// unauthenticated users to `/sign-in` and back to `/` once signed in.
/// While the auth state is still loading the router stays put to avoid
/// a splash flicker.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      // While we don't know yet, stay on the requested page (splash visible).
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;
      final loggedIn = user != null;
      final atSignIn = state.matchedLocation == '/sign-in';

      if (!loggedIn && !atSignIn) return '/sign-in';
      if (loggedIn && atSignIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/decks/new',
        builder: (context, state) => const CreateDeckScreen(),
      ),
      GoRoute(
        path: '/decks/:id',
        builder: (context, state) =>
            DeckDetailScreen(deckId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/decks/:id/edit',
        builder: (context, state) =>
            EditDeckScreen(deckId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/decks/:id/cards/new',
        builder: (context, state) =>
            AddCardScreen(deckId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/decks/:id/cards/:cardId/edit',
        builder: (context, state) => EditCardScreen(
          deckId: state.pathParameters['id']!,
          cardId: state.pathParameters['cardId']!,
        ),
      ),
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

/// A [ChangeNotifier] that mirrors [authStateChangesProvider] emissions.
///
/// GoRouter's refreshListenable calls the router's redirect whenever
/// this notifier fires, so the auth guard always sees the latest
/// [AuthUser?] value.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    _sub = _ref.listen<AsyncValue<AuthUser?>>(
      authStateChangesProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AuthUser?>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
