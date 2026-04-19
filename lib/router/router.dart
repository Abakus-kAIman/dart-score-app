import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../screens/setup/setup_screen.dart';
import '../screens/scoring/scoring_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/history/match_detail_screen.dart';
import '../models/match.dart';

// Notifies go_router when game state changes so the redirect re-evaluates,
// without recreating the GoRouter instance (which would reset navigation).
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<DartsMatch?>(gameProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final inGame = ref.read(gameProvider) != null;
      final onScoring = state.matchedLocation == '/scoring';

      if (inGame && !onScoring) return '/scoring';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/scoring',
        builder: (context, state) => const ScoringScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final match = state.extra as DartsMatch;
              return MatchDetailScreen(match: match);
            },
          ),
        ],
      ),
    ],
  );
});
