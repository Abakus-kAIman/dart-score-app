import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/leg.dart';
import '../../models/match.dart';
import '../../models/turn.dart';

final _dateFmt = DateFormat('MMM d, yyyy  HH:mm');

class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.match});

  final DartsMatch match;

  @override
  Widget build(BuildContext context) {
    final winner = match.winnerId != null
        ? match.players.firstWhere((p) => p.id == match.winnerId,
            orElse: () => match.players.first)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Detail'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_dateFmt.format(match.createdAt),
                        style: const TextStyle(color: Colors.white54)),
                    const SizedBox(height: 8),
                    Text(
                      match.players.map((p) {
                        final w = match.legWins[p.id] ?? 0;
                        return '${p.name}: $w leg${w == 1 ? '' : 's'}';
                      }).join('  |  '),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (winner != null) ...[
                      const SizedBox(height: 4),
                      Text('Winner: ${winner.name}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${match.startingScore} • Best of ${match.legsToWin * 2 - 1} • '
                      '${match.doubleOut ? "Double Out" : "Straight Out"}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...match.legs.where((l) => l.turns.isNotEmpty).map(
                  (leg) => _LegDetail(leg: leg, match: match),
                ),
          ],
        ),
      ),
    );
  }
}

class _LegDetail extends StatelessWidget {
  const _LegDetail({required this.leg, required this.match});

  final Leg leg;
  final DartsMatch match;

  @override
  Widget build(BuildContext context) {
    final winner = leg.winnerId != null
        ? match.players.firstWhere((p) => p.id == leg.winnerId,
            orElse: () => match.players.first)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text('Leg ${leg.legNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (winner != null)
                  Text('Won by ${winner.name}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13)),
              ],
            ),
          ),
          ...leg.turns.map((turn) => _TurnRow(turn: turn)),
        ],
      ),
    );
  }
}

class _TurnRow extends StatelessWidget {
  const _TurnRow({required this.turn});

  final Turn turn;

  @override
  Widget build(BuildContext context) {
    final bgColor = turn.isBust
        ? Colors.red.withOpacity(0.08)
        : turn.isCheckout
            ? Colors.green.withOpacity(0.1)
            : null;

    String dartsText = '';
    if (turn.darts != null) {
      dartsText = turn.darts!.map((d) => d.toString()).join(', ');
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(turn.playerName,
                style: const TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${turn.remainingBefore} → ${turn.remainingAfter}'
                  '${turn.isBust ? "  BUST" : turn.isCheckout ? "  ✓" : ""}',
                  style: TextStyle(
                      color: turn.isBust
                          ? Colors.redAccent
                          : turn.isCheckout
                              ? Colors.greenAccent
                              : Colors.white70,
                      fontSize: 13),
                ),
                if (dartsText.isNotEmpty)
                  Text(dartsText,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(
            turn.isBust ? 'Bust' : '−${turn.score}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: turn.isBust ? Colors.redAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
