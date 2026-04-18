import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/darts_rules.dart';

class ScoreInputTotal extends StatefulWidget {
  const ScoreInputTotal({super.key, required this.onSubmit});

  final Future<void> Function(int score) onSubmit;

  @override
  State<ScoreInputTotal> createState() => _ScoreInputTotalState();
}

class _ScoreInputTotalState extends State<ScoreInputTotal> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([int? quickScore]) async {
    final scoreText =
        quickScore != null ? '$quickScore' : _controller.text.trim();
    final score = int.tryParse(scoreText);

    if (score == null || !DartsRules.isValidTotalScore(score)) {
      setState(() => _error = 'Enter 0–180');
      return;
    }

    setState(() => _error = null);
    _controller.clear();
    await widget.onSubmit(score);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick score grid — wraps into multiple rows
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: DartsRules.commonScores
                .map((s) => _QuickScoreButton(
                      score: s,
                      onTap: () => _submit(s),
                      accent: accent,
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Manual input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Enter score (0–180)',
                    errorText: _error,
                    prefixIcon: const Icon(Icons.sports_bar),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (_) => _submit(),
                  autofocus: false,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
                child: const Text('Confirm',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickScoreButton extends StatelessWidget {
  const _QuickScoreButton({
    required this.score,
    required this.onTap,
    required this.accent,
  });

  final int score;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      splashColor: accent.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(7),
          color: const Color(0xFF2A2A2A),
        ),
        child: Text(
          '$score',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }
}
