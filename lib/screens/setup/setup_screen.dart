import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/match.dart';
import '../../providers/game_provider.dart';
import '../../utils/storage_service.dart';

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

  // Game mode
  GameMode _gameMode = GameMode.standard;

  // Standard mode: optional turn limit (0 = disabled)
  bool _turnLimitEnabled = false;
  int _standardMaxTurns = 10;

  // Count-up mode: mandatory turn count
  int _countUpTurns = 10;

  @override
  void initState() {
    super.initState();
    _loadLastSettings();
  }

  Future<void> _loadLastSettings() async {
    final storage = await StorageService.getInstance();
    final settings = await storage.loadLastSettings();
    if (settings == null || !mounted) return;

    final names = (settings['playerNames'] as List?)?.cast<String>() ?? [];
    final score = settings['startingScore'] as int? ?? 501;
    final doubleOut = settings['doubleOut'] as bool? ?? true;
    final legs = settings['legsToWin'] as int? ?? 3;
    final gameModeStr = settings['gameMode'] as String? ?? 'standard';
    final maxTurns = settings['maxTurnsPerLeg'] as int? ?? 0;

    setState(() {
      for (final c in _playerControllers) c.dispose();
      _playerControllers.clear();
      final count = names.length.clamp(2, 8);
      for (var i = 0; i < count; i++) {
        _playerControllers.add(
            TextEditingController(text: i < names.length ? names[i] : ''));
      }

      if (score == 301 || score == 501) {
        _startingScore = score;
        _useCustomScore = false;
      } else {
        _useCustomScore = true;
        _customScoreController.text = '$score';
      }
      _doubleOut = doubleOut;
      _legsToWin = legs;
      _gameMode = GameMode.values.byName(gameModeStr);
      if (_gameMode == GameMode.countUp) {
        _countUpTurns = maxTurns > 0 ? maxTurns : 10;
      } else {
        _turnLimitEnabled = maxTurns > 0;
        _standardMaxTurns = maxTurns > 0 ? maxTurns : 10;
      }
    });
  }

  @override
  void dispose() {
    for (final c in _playerControllers) c.dispose();
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
    if (_gameMode == GameMode.standard && _useCustomScore) {
      final val = int.tryParse(_customScoreController.text.trim());
      if (val == null || val <= 0 || val % 2 != 1) {
        setState(() =>
            _error = 'Custom score must be a positive odd number (e.g. 701)');
        return;
      }
      score = val;
    }

    final names = _playerControllers.map((c) => c.text.trim()).toList();
    final maxTurns = _gameMode == GameMode.countUp
        ? _countUpTurns
        : (_turnLimitEnabled ? _standardMaxTurns : 0);

    final storage = await StorageService.getInstance();
    await storage.saveLastSettings(
      playerNames: names,
      startingScore: score,
      doubleOut: _doubleOut,
      legsToWin: _legsToWin,
      gameMode: _gameMode,
      maxTurnsPerLeg: maxTurns,
    );

    await ref.read(gameProvider.notifier).startMatch(
          playerNames: names,
          startingScore: score,
          doubleOut: _doubleOut,
          legsToWin: _legsToWin,
          gameMode: _gameMode,
          maxTurnsPerLeg: maxTurns,
        );

    if (mounted) context.go('/scoring');
  }

  @override
  Widget build(BuildContext context) {
    final isCountUp = _gameMode == GameMode.countUp;

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
                // ── Game Mode ─────────────────────────────────────────────
                _SectionHeader('Game Mode'),
                const SizedBox(height: 12),
                SegmentedButton<GameMode>(
                  segments: const [
                    ButtonSegment(
                      value: GameMode.standard,
                      label: Text('Standard 01'),
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                    ButtonSegment(
                      value: GameMode.countUp,
                      label: Text('Count-Up'),
                      icon: Icon(Icons.add_circle_outline),
                    ),
                  ],
                  selected: {_gameMode},
                  onSelectionChanged: (s) =>
                      setState(() => _gameMode = s.first),
                ),
                const SizedBox(height: 8),
                if (isCountUp)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Players start at 0 and accumulate score. Highest score after all turns wins each leg.',
                      style: TextStyle(fontSize: 13, color: Colors.white60),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Players ───────────────────────────────────────────────
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

                // ── Count-Up: turns per player ────────────────────────────
                if (isCountUp) ...[
                  _SectionHeader('Turns per Player'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Each player throws  '),
                      _NumberStepper(
                        value: _countUpTurns,
                        min: 1,
                        max: 50,
                        onChanged: (v) => setState(() => _countUpTurns = v),
                      ),
                      const Text('  turns'),
                    ],
                  ),
                ],

                // ── Standard: starting score + rules ─────────────────────
                if (!isCountUp) ...[
                  _SectionHeader('Starting Score'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final score in [301, 501])
                        ChoiceChip(
                          label: Text('$score'),
                          selected:
                              !_useCustomScore && _startingScore == score,
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
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
                    subtitle:
                        const Text('Must finish on a double or bull (50)'),
                    value: _doubleOut,
                    onChanged: (v) => setState(() => _doubleOut = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Turn Limit per Leg'),
                    subtitle: const Text(
                        'Leg ends after N rounds; lowest score wins'),
                    value: _turnLimitEnabled,
                    onChanged: (v) =>
                        setState(() => _turnLimitEnabled = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_turnLimitEnabled) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        const Text('Max rounds per leg:  '),
                        _NumberStepper(
                          value: _standardMaxTurns,
                          min: 1,
                          max: 50,
                          onChanged: (v) =>
                              setState(() => _standardMaxTurns = v),
                        ),
                      ],
                    ),
                  ],
                ],

                const SizedBox(height: 24),

                // ── Match Format ──────────────────────────────────────────
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
                  label: Text(
                    isCountUp ? 'Start Count-Up' : 'Start Game',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
