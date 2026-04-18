import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/match.dart';
import '../../providers/game_provider.dart';

final _dateFmt = DateFormat('MMM d, yyyy  HH:mm');

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(matchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
        backgroundColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matches) => matches.isEmpty
            ? const Center(
                child: Text('No completed matches yet.',
                    style: TextStyle(color: Colors.white54)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: matches.length,
                itemBuilder: (ctx, i) => _MatchCard(match: matches[i]),
              ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final DartsMatch match;

  @override
  Widget build(BuildContext context) {
    final winner = match.winnerId != null
        ? match.players.firstWhere((p) => p.id == match.winnerId,
            orElse: () => match.players.first)
        : null;

    final scoreText = match.players.map((p) {
      final w = match.legWins[p.id] ?? 0;
      return '${p.name} $w';
    }).join(' – ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => context.go('/history/detail', extra: match),
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          scoreText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${match.startingScore} • Best of ${match.legsToWin * 2 - 1} • '
              '${match.doubleOut ? "Double Out" : "Straight Out"}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (winner != null)
              Text(
                'Winner: ${winner.name}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
          ],
        ),
        trailing: Text(
          _dateFmt.format(match.createdAt),
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ),
    );
  }
}
