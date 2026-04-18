import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../screens/setup/setup_screen.dart';
import '../screens/scoring/scoring_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/history/match_detail_screen.dart';
import '../models/match.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final gameState = ref.watch(gameProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final inGame = gameState != null;
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
