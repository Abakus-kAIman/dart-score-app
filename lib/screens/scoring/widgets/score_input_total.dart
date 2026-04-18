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
    final scoreText = quickScore != null ? '$quickScore' : _controller.text.trim();
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
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick score buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: DartsRules.commonScores
                .map((s) => _QuickScoreButton(
                      score: s,
                      onTap: () => _submit(s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Enter score (0-180)',
                    errorText: _error,
                    prefixIcon: const Icon(Icons.sports_bar),
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
                      horizontal: 20, vertical: 16),
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
  const _QuickScoreButton({required this.score, required this.onTap});

  final int score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF2A2A2A),
        ),
        child: Text(
          '$score',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
