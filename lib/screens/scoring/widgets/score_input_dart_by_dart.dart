import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/dart_throw.dart';
import '../../../providers/game_provider.dart';
import '../../../utils/checkout_table.dart';

class ScoreInputDartByDart extends ConsumerStatefulWidget {
  const ScoreInputDartByDart({
    super.key,
    required this.onConfirm,
    required this.playerRemaining,
  });

  final Future<void> Function() onConfirm;
  final int playerRemaining;

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
    setState(() => _multiplier = 1);
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
    final accent = Theme.of(context).colorScheme.primary;

    final projected = widget.playerRemaining - subtotal;
    final dartsLeft = 3 - darts.length;
    final liveCheckout = (subtotal > 0 && projected >= 2 && projected <= 170)
        ? CheckoutTable.suggestForDartsLeft(projected, dartsLeft)
        : null;
    final showLive = subtotal > 0;

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dart slots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _DartChip(
                    dart: i < darts.length ? darts[i] : null,
                    index: i,
                    accent: accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Live score row
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: showLive
                ? _LiveScoreBar(
                    key: ValueKey(projected),
                    subtotal: subtotal,
                    projected: projected,
                    checkoutRoute: liveCheckout,
                    accent: accent,
                  )
                : const SizedBox(height: 20),
          ),
          const SizedBox(height: 6),
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
                  _multiplier == 3,
                ],
                onPressed: isFull
                    ? null
                    : (i) => setState(() => _multiplier = i + 1),
                borderRadius: BorderRadius.circular(8),
                selectedColor: Colors.white,
                fillColor: accent,
                constraints:
                    const BoxConstraints(minWidth: 48, minHeight: 34),
                children: const [
                  Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('D', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Number grid — shrinkWrap so it shows all 3 rows naturally
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              mainAxisExtent: 42,
            ),
            itemCount: 21, // 1–20 + bull
            itemBuilder: (ctx, i) {
              final value = i == 20 ? 25 : i + 1;
              final label = value == 25 ? 'Bull' : '$value';
              final disabled = isFull || (value == 25 && _multiplier == 3);
              return _GridBtn(
                label: label,
                onTap: disabled ? null : () => _addDart(value),
                accent: accent,
              );
            },
          ),
          const SizedBox(height: 8),
          // Action row
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isFull ? null : _addMiss,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Miss'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const Spacer(),
              if (darts.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    ref.read(dartInputProvider.notifier).removeLast();
                    setState(() => _multiplier = 1);
                  },
                  icon: const Icon(Icons.backspace_outlined, size: 16),
                  label: const Text('Undo'),
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
  const _DartChip({
    required this.dart,
    required this.index,
    required this.accent,
  });

  final DartThrow? dart;
  final int index;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final filled = dart != null;
    return Container(
      width: 80,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? accent.withOpacity(0.25) : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: filled ? accent : Colors.white24),
      ),
      child: Text(
        dart?.toString() ?? 'Dart ${index + 1}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: filled ? Colors.white : Colors.white38,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _LiveScoreBar extends StatelessWidget {
  const _LiveScoreBar({
    super.key,
    required this.subtotal,
    required this.projected,
    required this.checkoutRoute,
    required this.accent,
  });

  final int subtotal;
  final int projected;
  final String? checkoutRoute;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Turn: $subtotal',
                style: const TextStyle(fontSize: 13, color: Colors.white54),
              ),
              const SizedBox(width: 8),
              const Text('→', style: TextStyle(color: Colors.white38)),
              const SizedBox(width: 8),
              Text(
                '$projected left',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: projected <= 170 ? accent : Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (checkoutRoute != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.track_changes, size: 12, color: accent),
                const SizedBox(width: 5),
                Text(
                  checkoutRoute!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accent,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _GridBtn extends StatelessWidget {
  const _GridBtn({
    required this.label,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? const Color(0xFF1E1E1E) : const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        splashColor: accent.withOpacity(0.3),
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
