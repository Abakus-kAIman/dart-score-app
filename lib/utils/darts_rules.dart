import '../models/dart_throw.dart';

class DartsRules {
  static bool isValidDoubleFinish(DartThrow dart) {
    return dart.isDouble && dart.value > 0;
  }

  static bool isBullseye(DartThrow dart) {
    return dart.multiplier == 2 && dart.value == 25;
  }

  /// Evaluate a turn in total mode.
  static ({int remaining, bool isBust, bool isCheckout}) evaluateTotalTurn({
    required int remainingBefore,
    required int score,
    required bool doubleOut,
    required bool finishedWithDouble,
  }) {
    final newRemaining = remainingBefore - score;

    if (newRemaining < 0) {
      return (remaining: remainingBefore, isBust: true, isCheckout: false);
    }

    if (newRemaining == 0) {
      if (doubleOut && !finishedWithDouble) {
        return (remaining: remainingBefore, isBust: true, isCheckout: false);
      }
      return (remaining: 0, isBust: false, isCheckout: true);
    }

    if (newRemaining == 1 && doubleOut) {
      return (remaining: remainingBefore, isBust: true, isCheckout: false);
    }

    return (remaining: newRemaining, isBust: false, isCheckout: false);
  }

  /// Evaluate a dart-by-dart turn.
  static ({int remaining, bool isBust, bool isCheckout}) evaluateDartByDartTurn({
    required int remainingBefore,
    required List<DartThrow> darts,
    required bool doubleOut,
  }) {
    int remaining = remainingBefore;

    for (final dart in darts) {
      final newRemaining = remaining - dart.points;

      if (newRemaining < 0) {
        return (remaining: remainingBefore, isBust: true, isCheckout: false);
      }

      if (newRemaining == 0) {
        if (doubleOut && !isValidDoubleFinish(dart) && !isBullseye(dart)) {
          return (remaining: remainingBefore, isBust: true, isCheckout: false);
        }
        return (remaining: 0, isBust: false, isCheckout: true);
      }

      if (newRemaining == 1 && doubleOut) {
        return (remaining: remainingBefore, isBust: true, isCheckout: false);
      }

      remaining = newRemaining;
    }

    return (remaining: remaining, isBust: false, isCheckout: false);
  }

  static bool isValidTotalScore(int score) => score >= 0 && score <= 180;

  static const List<int> commonScores = [
    0, 1, 3, 5, 11, 20, 21, 22, 25, 26,
    41, 45, 57, 60, 80, 81, 85, 100, 121, 140, 180,
  ];

  static bool couldBeCheckout(int remaining, bool doubleOut) {
    if (remaining <= 0) return false;
    if (remaining > 170) return false;
    if (doubleOut && remaining == 1) return false;
    const impossible = {169, 168, 166, 165, 163, 162, 159};
    return !impossible.contains(remaining);
  }
}
