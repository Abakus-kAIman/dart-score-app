import 'package:flutter/material.dart';
import '../../../models/leg.dart';
import '../../../models/turn.dart';

class TurnHistoryPanel extends StatelessWidget {
  const TurnHistoryPanel({super.key, required this.leg});

  final Leg leg;

  @override
  Widget build(BuildContext context) {
    final turns = leg.turns.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(left: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF222222),
            child: Text(
              'Turn History – Leg ${leg.legNumber}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white70),
            ),
          ),
          Expanded(
            child: turns.isEmpty
                ? const Center(
                    child: Text('No turns yet',
                        style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: turns.length,
                    itemBuilder: (ctx, i) => _TurnTile(turn: turns[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TurnTile extends StatelessWidget {
  const _TurnTile({required this.turn});

  final Turn turn;

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    if (turn.isBust) bgColor = Colors.red.withOpacity(0.1);
    if (turn.isCheckout) bgColor = Colors.green.withOpacity(0.15);

    String subtitle;
    if (turn.isBust) {
      subtitle = 'BUST  ${turn.remainingBefore} → ${turn.remainingAfter}';
    } else if (turn.isCheckout) {
      subtitle = 'CHECKOUT!  ${turn.remainingBefore} → 0';
    } else {
      subtitle = '${turn.remainingBefore} → ${turn.remainingAfter}';
    }

    String dartsText = '';
    if (turn.darts != null) {
      dartsText = turn.darts!.map((d) => d.toString()).join(', ');
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(turn.playerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
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
              fontSize: 16,
              color: turn.isBust
                  ? Colors.redAccent
                  : turn.isCheckout
                      ? Colors.greenAccent
                      : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
