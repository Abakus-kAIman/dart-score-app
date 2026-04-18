import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/match.dart';
import '../../models/turn.dart';
import '../../providers/game_provider.dart';
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

  Future<void> _submitTotal(int score) async {
    final match = ref.read(gameProvider)!;

    // With double-out, hitting exactly 0 requires asking about finish dart
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
      _showLegWonSnackbar();
    }
  }

  void _showLegWonSnackbar() {
    // Match is still in state here; show brief notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leg won! Next leg starting...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showMatchWonDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Match Over!'),
        content: const Text('The match has been saved to history.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            child: const Text('New Game'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/history');
            },
            child: const Text('View History'),
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
            child:
                const Text('Abandon', style: TextStyle(color: Colors.redAccent)),
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
            onPressed: () =>
                ref.read(gameProvider.notifier).undoLastTurn(),
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
          onChanged: (m) {
            setState(() => _inputMode = m);
            ref.read(dartInputProvider.notifier).clear();
          },
        ),
        if (_inputMode == TurnMode.total)
          ScoreInputTotal(onSubmit: _submitTotal)
        else
          ScoreInputDartByDart(onConfirm: _submitDartByDart),
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
    final scoreText = match.players
        .map((p) => '${p.name} ${wins[p.id] ?? 0}')
        .join(' – ');
    final legText = 'Leg ${match.currentLegIndex + 1}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(scoreText,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(legText,
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

    final others = match.players.where((p) => p.id != currentPlayerId).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Active player — big display
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                  if (match.doubleOut && currentRemaining <= 170 && currentRemaining > 1)
                    Text(
                      'Checkout!',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Other players
          ...others.map((p) {
            final rem = notifier.remainingForPlayer(p.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.person_outline, color: Colors.white54),
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
