import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/dart_throw.dart';
import '../models/leg.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../models/turn.dart';
import '../utils/darts_rules.dart';
import '../utils/storage_service.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Storage provider
// ---------------------------------------------------------------------------
final storageServiceProvider = FutureProvider<StorageService>((ref) async {
  return StorageService.getInstance();
});

// ---------------------------------------------------------------------------
// Active match state
// ---------------------------------------------------------------------------
class GameNotifier extends Notifier<DartsMatch?> {
  /// Preserved after match completes so the UI can read it after state → null.
  String? lastWinnerName;

  @override
  DartsMatch? build() => null;

  // ── Setup ────────────────────────────────────────────────────────────────

  Future<void> startMatch({
    required List<String> playerNames,
    required int startingScore,
    required bool doubleOut,
    required int legsToWin,
  }) async {
    final players = playerNames
        .asMap()
        .entries
        .map((e) => Player(
              id: _uuid.v4(),
              name: e.value.isEmpty ? 'Player ${e.key + 1}' : e.value,
            ))
        .toList();

    final firstLeg = _createLeg(1);
    final match = DartsMatch(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      players: players,
      startingScore: startingScore,
      doubleOut: doubleOut,
      legsToWin: legsToWin,
      currentLegIndex: 0,
      completed: false,
      legs: [firstLeg],
    );
    state = match;
    await _save();
  }

  Future<void> loadSaved() async {
    final storage = await StorageService.getInstance();
    state = await storage.loadActiveMatch();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Leg _createLeg(int legNumber, {int startPlayerIndex = 0}) => Leg(
        id: _uuid.v4(),
        legNumber: legNumber,
        turns: const [],
        startPlayerIndex: startPlayerIndex,
      );

  String _currentPlayerId() {
    final match = state!;
    final leg = match.currentLeg;
    final idx = (leg.startPlayerIndex + leg.turns.length) % match.players.length;
    return match.players[idx].id;
  }

  Player _playerById(String id) =>
      state!.players.firstWhere((p) => p.id == id);

  int _remainingFor(String playerId) {
    final match = state!;
    final leg = match.currentLeg;
    final playerTurns = leg.turns.where((t) => t.playerId == playerId);
    if (playerTurns.isEmpty) return match.startingScore;
    return playerTurns.last.remainingAfter;
  }

  Future<void> _save() async {
    if (state == null) return;
    final storage = await StorageService.getInstance();
    await storage.saveActiveMatch(state!);
  }

  Future<void> _completeMatch(String winnerId) async {
    lastWinnerName = _playerById(winnerId).name;
    final storage = await StorageService.getInstance();
    final completed = state!.copyWith(completed: true, winnerId: winnerId);
    await storage.saveCompletedMatch(completed);
    await storage.clearActiveMatch();
    state = null;
  }

  // ── Turn submission ──────────────────────────────────────────────────────

  /// Called in total mode. [finishedWithDouble] is asked via dialog when
  /// remaining would reach 0 with double-out ON.
  Future<TurnResult> submitTotalTurn({
    required int score,
    bool finishedWithDouble = false,
  }) async {
    final match = state!;
    final playerId = _currentPlayerId();
    final player = _playerById(playerId);
    final remainingBefore = _remainingFor(playerId);

    final eval = DartsRules.evaluateTotalTurn(
      remainingBefore: remainingBefore,
      score: score,
      doubleOut: match.doubleOut,
      finishedWithDouble: finishedWithDouble,
    );

    final turn = Turn(
      id: _uuid.v4(),
      playerId: playerId,
      playerName: player.name,
      turnIndex: match.currentLeg.turns.length,
      mode: TurnMode.total,
      score: score,
      remainingBefore: remainingBefore,
      remainingAfter: eval.remaining,
      isBust: eval.isBust,
      isCheckout: eval.isCheckout,
    );

    return _applyTurn(turn);
  }

  Future<TurnResult> submitDartByDartTurn(List<DartThrow> darts) async {
    final match = state!;
    final playerId = _currentPlayerId();
    final player = _playerById(playerId);
    final remainingBefore = _remainingFor(playerId);
    final score = darts.fold(0, (sum, d) => sum + d.points);

    final eval = DartsRules.evaluateDartByDartTurn(
      remainingBefore: remainingBefore,
      darts: darts,
      doubleOut: match.doubleOut,
    );

    final turn = Turn(
      id: _uuid.v4(),
      playerId: playerId,
      playerName: player.name,
      turnIndex: match.currentLeg.turns.length,
      mode: TurnMode.dartByDart,
      darts: darts,
      score: score,
      remainingBefore: remainingBefore,
      remainingAfter: eval.remaining,
      isBust: eval.isBust,
      isCheckout: eval.isCheckout,
    );

    return _applyTurn(turn);
  }

  Future<TurnResult> _applyTurn(Turn turn) async {
    final match = state!;
    final leg = match.currentLeg;
    final newTurns = [...leg.turns, turn];
    var newLeg = leg.copyWith(turns: newTurns);
    var newLegs = [...match.legs];

    TurnResult result = TurnResult.normal;

    if (turn.isCheckout) {
      newLeg = newLeg.copyWith(winnerId: turn.playerId);
      newLegs[match.currentLegIndex] = newLeg;

      final wins = _legWinsFromLegs(newLegs, match.players);
      if ((wins[turn.playerId] ?? 0) >= match.legsToWin) {
        state = match.copyWith(legs: newLegs, completed: false);
        await _completeMatch(turn.playerId);
        return TurnResult.matchWon;
      }

      // Start next leg — rotate starting player by one each leg
      final nextLegNumber = match.currentLegIndex + 2;
      final nextStartPlayerIndex = (match.currentLegIndex + 1) % match.players.length;
      final nextLeg = _createLeg(nextLegNumber, startPlayerIndex: nextStartPlayerIndex);
      newLegs.add(nextLeg);
      state = match.copyWith(
        legs: newLegs,
        currentLegIndex: match.currentLegIndex + 1,
      );
      await _save();
      return TurnResult.legWon;
    }

    newLegs[match.currentLegIndex] = newLeg;
    state = match.copyWith(legs: newLegs);
    await _save();
    return result;
  }

  Map<String, int> _legWinsFromLegs(List<Leg> legs, List<Player> players) {
    final wins = <String, int>{};
    for (final p in players) {
      wins[p.id] = 0;
    }
    for (final leg in legs) {
      if (leg.winnerId != null) {
        wins[leg.winnerId!] = (wins[leg.winnerId!] ?? 0) + 1;
      }
    }
    return wins;
  }

  // ── Undo ─────────────────────────────────────────────────────────────────

  Future<void> undoLastTurn() async {
    final match = state!;
    var legs = [...match.legs];
    var currentLegIndex = match.currentLegIndex;
    var leg = legs[currentLegIndex];

    // If current leg has no turns, undo into the previous leg
    if (leg.turns.isEmpty) {
      if (currentLegIndex == 0) return; // nothing to undo
      currentLegIndex--;
      legs.removeLast(); // remove empty leg
      leg = legs[currentLegIndex];
    }

    if (leg.turns.isEmpty) return;

    final newTurns = leg.turns.sublist(0, leg.turns.length - 1);
    final wasCheckout = leg.turns.last.isCheckout;
    final newLeg = leg.copyWith(
      turns: newTurns,
      clearWinner: wasCheckout,
    );
    legs[currentLegIndex] = newLeg;

    state = match.copyWith(legs: legs, currentLegIndex: currentLegIndex);
    await _save();
  }

  // ── Derived getters ──────────────────────────────────────────────────────

  String? get currentPlayerId => state == null ? null : _currentPlayerId();

  String? get legStartPlayerName {
    if (state == null) return null;
    final idx = state!.currentLeg.startPlayerIndex;
    return state!.players[idx].name;
  }

  /// Change who throws first in the current leg. Only effective before any
  /// turns have been taken in the leg.
  Future<void> setLegStartPlayer(int playerIndex) async {
    final match = state!;
    if (match.currentLeg.turns.isNotEmpty) return;
    final newLeg = match.currentLeg.copyWith(startPlayerIndex: playerIndex);
    final newLegs = [...match.legs];
    newLegs[match.currentLegIndex] = newLeg;
    state = match.copyWith(legs: newLegs);
    await _save();
  }

  int remainingForPlayer(String playerId) {
    if (state == null) return 0;
    return _remainingFor(playerId);
  }

  void abandonMatch() {
    state = null;
    StorageService.getInstance().then((s) => s.clearActiveMatch());
  }
}

enum TurnResult { normal, legWon, matchWon }

final gameProvider = NotifierProvider<GameNotifier, DartsMatch?>(
  GameNotifier.new,
);

// ---------------------------------------------------------------------------
// Dart-by-dart input state
// ---------------------------------------------------------------------------
class DartInputNotifier extends Notifier<List<DartThrow>> {
  @override
  List<DartThrow> build() => [];

  void addDart(DartThrow dart) {
    if (state.length >= 3) return;
    state = [...state, dart];
  }

  void removeLast() {
    if (state.isEmpty) return;
    state = state.sublist(0, state.length - 1);
  }

  void clear() {
    state = [];
  }

  int get subtotal => state.fold(0, (sum, d) => sum + d.points);
  bool get canConfirm => state.isNotEmpty;
  bool get isFull => state.length >= 3;
}

final dartInputProvider = NotifierProvider<DartInputNotifier, List<DartThrow>>(
  DartInputNotifier.new,
);

// ---------------------------------------------------------------------------
// Match history provider
// ---------------------------------------------------------------------------
final matchHistoryProvider = FutureProvider<List<DartsMatch>>((ref) async {
  final storage = await StorageService.getInstance();
  return storage.loadCompletedMatches();
});
