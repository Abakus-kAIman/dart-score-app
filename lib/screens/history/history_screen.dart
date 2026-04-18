import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/match.dart';
import '../../providers/game_provider.dart';
import '../../utils/storage_service.dart';

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
      body: Column(
        children: [
          _DataLocationBanner(),
          Expanded(
            child: historyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (matches) => matches.isEmpty
                  ? const Center(
                      child: Text('No completed matches yet.',
                          style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: matches.length,
                      itemBuilder: (ctx, i) =>
                          _MatchCard(match: matches[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows where data files are stored. Only visible on desktop builds.
class _DataLocationBanner extends StatefulWidget {
  @override
  State<_DataLocationBanner> createState() => _DataLocationBannerState();
}

class _DataLocationBannerState extends State<_DataLocationBanner> {
  String? _path;

  @override
  void initState() {
    super.initState();
    StorageService.getInstance().then((s) {
      if (mounted) setState(() => _path = s.dataLocation);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_path == null || _path == 'Browser localStorage') {
      return const SizedBox.shrink();
    }
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.folder_open, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data stored at: $_path',
              style: const TextStyle(fontSize: 11, color: Colors.white38),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Copy path',
            icon: const Icon(Icons.copy, size: 14, color: Colors.white38),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _path!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Path copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

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
