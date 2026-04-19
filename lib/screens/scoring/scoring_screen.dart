import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/match.dart';
import '../../models/turn.dart';
import '../../providers/game_provider.dart';
import '../../utils/checkout_table.dart';
import '../../utils/storage_service.dart';
import 'widgets/score_input_total.dart';
import 'widgets/score_input_dart_by_dart.dart';
import 'widgets/turn_history_panel.dart';

class ScoringScreen extends ConsumerStatefulWidget {
  const ScoringScreen({super.key});

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  TurnMode _inputMode = TurnMode.total;
  bool _historyVisible = false;

  @override
  void initState() {
    super.initState();
    StorageService.getInstance().then((s) async {
      final mode = await s.loadInputMode();
      if (mode != null && mounted) {
        setState(() {
          _inputMode =
              mode == 'dartByDart' ? TurnMode.dartByDart : TurnMode.total;
        });
      }
    });
  }

  void _setInputMode(TurnMode mode) {
    setState(() => _inputMode = mode);
    ref.read(dartInputProvider.notifier).clear();
    StorageService.getInstance().then(
      (s) => s.saveInputMode(mode == TurnMode.dartByDart ? 'dartByDart' : 'total'),
    );
  }

  Future<void> _submitTotal(int score) async {
    final match = ref.read(gameProvider)!;

    if (match.doubleOut) {
      final currentId = ref.read(gameProvider.notifier).currentPlayerId!;
      final remaining =
          ref.read(gameProvider.notifier).remainingForPlayer(currentId);

      if (remaining - score == 0) {
        final answer = await _askDoubleOutFinish();
        if (answer == null) return;
        final result = await ref.read(gameProvider.notifier).submitTotalTurn(
              score: score,
              finishedWithDouble: answer,
            );
        _handleResult(result);
        return;
      }
    }

    final result =
        await ref.read(gameProvider.notifier).submitTotalTurn(score: score);
    _handleResult(result);
  }

  Future<bool?> _askDoubleOutFinish() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Dart'),
        content: const Text('What was the finishing dart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Invalid / Bust'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bull 25'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Double / Bull 50'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDartByDart() async {
    final darts = ref.read(dartInputProvider);
    if (darts.isEmpty) return;
    ref.read(dartInputProvider.notifier).clear();
    final result =
        await ref.read(gameProvider.notifier).submitDartByDartTurn(darts);
    _handleResult(result);
  }

  void _handleResult(TurnResult result) {
    if (!mounted) return;
    if (result == TurnResult.matchWon) {
      _showMatchWonDialog();
    } else if (result == TurnResult.legWon) {
      _showLegWonDialog();
    }
  }

  void _showLegWonDialog() {
    final match = ref.read(gameProvider);
    if (match == null) return;

    final completedLeg = match.legs[match.currentLegIndex - 1];
    final winner = match.players.firstWhere(
      (p) => p.id == completedLeg.winnerId,
      orElse: () => match.players.first,
    );
    final wins = match.legWins;
    final scoreText =
        match.players.map((p) => '${p.name}  ${wins[p.id] ?? 0}').join('   ');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 2800), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });

        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CHECKOUT!',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                winner.name,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold),
              ),
              Text(
                'won leg ${completedLeg.legNumber}',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  scoreText,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showMatchWonDialog() {
    final winnerName =
        ref.read(gameProvider.notifier).lastWinnerName ?? 'Player';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🏆',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              winnerName,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'wins the match!',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Match saved to history.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/history');
            },
            child: const Text('View History'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAbandon() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandon Match?'),
        content: const Text('Progress will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abandon',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(gameProvider.notifier).abandonMatch();
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(gameProvider);
    if (match == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmAbandon,
        ),
        title: _MatchScoreHeader(match: match),
        actions: [
          IconButton(
            tooltip: 'Undo last turn',
            icon: const Icon(Icons.undo),
            onPressed: () => ref.read(gameProvider.notifier).undoLastTurn(),
          ),
          IconButton(
            tooltip: 'Turn history',
            icon: Icon(
              Icons.history,
              color: _historyVisible
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () =>
                setState(() => _historyVisible = !_historyVisible),
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(child: _mainContent(match)),
                if (_historyVisible)
                  SizedBox(
                    width: 320,
                    child: TurnHistoryPanel(leg: match.currentLeg),
                  ),
              ],
            )
          : Column(
              children: [
                Expanded(child: _mainContent(match)),
                if (_historyVisible)
                  SizedBox(
                    height: 260,
                    child: TurnHistoryPanel(leg: match.currentLeg),
                  ),
              ],
            ),
    );
  }

  Widget _mainContent(DartsMatch match) {
    final notifier = ref.read(gameProvider.notifier);
    final currentId = notifier.currentPlayerId!;

    return Column(
      children: [
        Expanded(
          child: _ScoreBoard(match: match, currentPlayerId: currentId),
        ),
        _InputModeToggle(
          mode: _inputMode,
          onChanged: _setInputMode,
        ),
        if (_inputMode == TurnMode.total)
          ScoreInputTotal(onSubmit: _submitTotal)
        else
          ScoreInputDartByDart(
            onConfirm: _submitDartByDart,
            playerRemaining: notifier.remainingForPlayer(currentId),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _MatchScoreHeader extends StatelessWidget {
  const _MatchScoreHeader({required this.match});
  final DartsMatch match;

  @override
  Widget build(BuildContext context) {
    final wins = match.legWins;
    final scoreText =
        match.players.map((p) => '${p.name} ${wins[p.id] ?? 0}').join(' – ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(scoreText,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text('Leg ${match.currentLegIndex + 1}',
            style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _ScoreBoard extends ConsumerWidget {
  const _ScoreBoard({required this.match, required this.currentPlayerId});

  final DartsMatch match;
  final String currentPlayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final currentPlayer =
        match.players.firstWhere((p) => p.id == currentPlayerId);
    final currentRemaining = notifier.remainingForPlayer(currentPlayerId);
    final others =
        match.players.where((p) => p.id != currentPlayerId).toList();

    final checkoutRoute = CheckoutTable.suggest(currentRemaining);
    final canCheckout = match.doubleOut
        ? currentRemaining <= 170 && currentRemaining > 1
        : currentRemaining <= 180 && currentRemaining > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // ── Active player card ──────────────────────────────────────────
          Card(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  Text(
                    currentPlayer.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$currentRemaining',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  if (canCheckout) ...[
                    const SizedBox(height: 6),
                    _CheckoutBadge(
                      route: checkoutRoute,
                      doubleOut: match.doubleOut,
                      remaining: currentRemaining,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── Other players ───────────────────────────────────────────────
          ...others.map((p) {
            final rem = notifier.remainingForPlayer(p.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline,
                      color: Colors.white54),
                  title: Text(p.name),
                  trailing: Text(
                    '$rem',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CheckoutBadge extends StatelessWidget {
  const _CheckoutBadge({
    required this.route,
    required this.doubleOut,
    required this.remaining,
  });

  final String? route;
  final bool doubleOut;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    if (!doubleOut) {
      // Straight-out: just flag it's reachable in ≤ 3 darts
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.4)),
        ),
        child: Text(
          'Finish possible',
          style: TextStyle(
              color: accent, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    }

    if (route == null) {
      // Impossible checkout (e.g. 169)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.4)),
        ),
        child: const Text(
          'No standard checkout',
          style: TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.track_changes, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            route!,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _InputModeToggle extends StatelessWidget {
  const _InputModeToggle({required this.mode, required this.onChanged});

  final TurnMode mode;
  final ValueChanged<TurnMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SegmentedButton<TurnMode>(
        segments: const [
          ButtonSegment(
            value: TurnMode.total,
            label: Text('Turn Total'),
            icon: Icon(Icons.format_list_numbered),
          ),
          ButtonSegment(
            value: TurnMode.dartByDart,
            label: Text('Dart by Dart'),
            icon: Icon(Icons.adjust),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
