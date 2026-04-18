import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/dart_throw.dart';
import '../../../providers/game_provider.dart';

class ScoreInputDartByDart extends ConsumerStatefulWidget {
  const ScoreInputDartByDart({super.key, required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  ConsumerState<ScoreInputDartByDart> createState() =>
      _ScoreInputDartByDartState();
}

class _ScoreInputDartByDartState extends ConsumerState<ScoreInputDartByDart> {
  int _multiplier = 1;

  void _addDart(int value) {
    ref.read(dartInputProvider.notifier).addDart(
          DartThrow(multiplier: _multiplier, value: value),
        );
    setState(() => _multiplier = 1); // reset to single after each dart
  }

  void _addMiss() {
    ref.read(dartInputProvider.notifier).addDart(
          const DartThrow(multiplier: 1, value: 0),
        );
    setState(() => _multiplier = 1);
  }

  @override
  Widget build(BuildContext context) {
    final darts = ref.watch(dartInputProvider);
    final notifier = ref.read(dartInputProvider.notifier);
    final isFull = notifier.isFull;
    final subtotal = notifier.subtotal;

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dart display row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _DartChip(
                    dart: i < darts.length ? darts[i] : null,
                    index: i,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Subtotal: $subtotal',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // Multiplier toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Multiplier: ',
                  style: TextStyle(color: Colors.white70)),
              ToggleButtons(
                isSelected: [
                  _multiplier == 1,
                  _multiplier == 2,
                  _multiplier == 3
                ],
                onPressed: isFull
                    ? null
                    : (i) => setState(() => _multiplier = i + 1),
                borderRadius: BorderRadius.circular(8),
                constraints:
                    const BoxConstraints(minWidth: 52, minHeight: 36),
                children: const [
                  Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('D', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Number grid
          SizedBox(
            height: 160,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.3,
              ),
              itemCount: 21, // 1-20 + bull
              itemBuilder: (ctx, i) {
                final value = i == 20 ? 25 : i + 1;
                final label = value == 25 ? 'Bull' : '$value';
                // Triple not valid for bull
                final disabled = isFull ||
                    (value == 25 && _multiplier == 3) ||
                    (_multiplier == 2 && value == 25 && false); // double bull OK
                return _GridBtn(
                  label: label,
                  onTap: disabled ? null : () => _addDart(value),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isFull ? null : _addMiss,
                icon: const Icon(Icons.close),
                label: const Text('Miss'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
              ),
              const Spacer(),
              if (darts.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    ref.read(dartInputProvider.notifier).removeLast();
                    setState(() => _multiplier = 1);
                  },
                  icon: const Icon(Icons.backspace_outlined),
                  label: const Text('Undo Dart'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: darts.isEmpty ? null : widget.onConfirm,
                child: const Text('Confirm Turn',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DartChip extends StatelessWidget {
  const _DartChip({required this.dart, required this.index});

  final DartThrow? dart;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dart != null ? const Color(0xFF2E7D32) : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dart != null ? Colors.green : Colors.white24,
        ),
      ),
      child: Text(
        dart?.toString() ?? 'Dart ${index + 1}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: dart != null ? Colors.white : Colors.white38,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _GridBtn extends StatelessWidget {
  const _GridBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? const Color(0xFF1E1E1E) : const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: onTap == null ? Colors.white24 : Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
