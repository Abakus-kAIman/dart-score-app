import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/game_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final List<TextEditingController> _playerControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _startingScore = 501;
  bool _doubleOut = true;
  int _legsToWin = 3;
  final _customScoreController = TextEditingController();
  bool _useCustomScore = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _playerControllers) {
      c.dispose();
    }
    _customScoreController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    if (_playerControllers.length >= 8) return;
    setState(() => _playerControllers.add(TextEditingController()));
  }

  void _removePlayer(int index) {
    if (_playerControllers.length <= 2) return;
    setState(() {
      _playerControllers[index].dispose();
      _playerControllers.removeAt(index);
    });
  }

  Future<void> _startGame() async {
    setState(() => _error = null);

    int score = _startingScore;
    if (_useCustomScore) {
      final val = int.tryParse(_customScoreController.text.trim());
      if (val == null || val <= 0 || val % 2 != 1) {
        setState(
            () => _error = 'Custom score must be a positive odd number (e.g. 701)');
        return;
      }
      score = val;
    }

    final names = _playerControllers.map((c) => c.text.trim()).toList();

    await ref.read(gameProvider.notifier).startMatch(
          playerNames: names,
          startingScore: score,
          doubleOut: _doubleOut,
          legsToWin: _legsToWin,
        );

    if (mounted) context.go('/scoring');
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Game'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/history'),
            icon: const Icon(Icons.history),
            label: const Text('History'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader('Players'),
                const SizedBox(height: 12),
                ..._playerControllers.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: e.value,
                              decoration: InputDecoration(
                                hintText: 'Player ${e.key + 1}',
                                prefixIcon: const Icon(Icons.person),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                          if (_playerControllers.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.redAccent),
                              onPressed: () => _removePlayer(e.key),
                            ),
                        ],
                      ),
                    )),
                if (_playerControllers.length < 8)
                  TextButton.icon(
                    onPressed: _addPlayer,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Player'),
                  ),
                const SizedBox(height: 24),
                _SectionHeader('Starting Score'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final score in [301, 501])
                      ChoiceChip(
                        label: Text('$score'),
                        selected: !_useCustomScore && _startingScore == score,
                        onSelected: (_) => setState(() {
                          _startingScore = score;
                          _useCustomScore = false;
                        }),
                      ),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: _useCustomScore,
                      onSelected: (_) =>
                          setState(() => _useCustomScore = true),
                    ),
                  ],
                ),
                if (_useCustomScore) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customScoreController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'e.g. 701',
                      prefixIcon: Icon(Icons.edit),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _SectionHeader('Rules'),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Double Out'),
                  subtitle: const Text(
                      'Must finish on a double or bull (50)'),
                  value: _doubleOut,
                  onChanged: (v) => setState(() => _doubleOut = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                _SectionHeader('Match Format'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('First to  '),
                    _NumberStepper(
                      value: _legsToWin,
                      min: 1,
                      max: 21,
                      onChanged: (v) => setState(() => _legsToWin = v),
                    ),
                    const Text('  legs'),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Game',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .headlineMedium
          ?.copyWith(fontSize: 18, color: Colors.white60),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text('$value',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
