import 'package:flutter_test/flutter_test.dart';
import 'package:dart_score_app/models/dart_throw.dart';
import 'package:dart_score_app/utils/darts_rules.dart';

void main() {
  group('DartsRules.evaluateTotalTurn', () {
    test('normal score reduces remaining', () {
      final result = DartsRules.evaluateTotalTurn(
        remainingBefore: 501,
        score: 60,
        doubleOut: true,
        finishedWithDouble: false,
      );
      expect(result.remaining, 441);
      expect(result.isBust, false);
      expect(result.isCheckout, false);
    });

    test('score going negative is bust', () {
      final result = DartsRules.evaluateTotalTurn(
        remainingBefore: 20,
        score: 40,
        doubleOut: false,
        finishedWithDouble: false,
      );
      expect(result.isBust, true);
      expect(result.remaining, 20);
    });

    test('exact 0 straight out is checkout', () {
      final result = DartsRules.evaluateTotalTurn(
        remainingBefore: 40,
        score: 40,
        doubleOut: false,
        finishedWithDouble: false,
      );
      expect(result.isCheckout, true);
      expect(result.remaining, 0);
    });

    test('exact 0 double-out without double is bust', () {
      final result = DartsRules.evaluateTotalTurn(
        remainingBefore: 40,
        score: 40,
        doubleOut: true,
        finishedWithDouble: false,
      );
      expect(result.isBust, true);
    });

    test('exact 0 double-out with double is checkout', () {
      final result = DartsRules.evaluateTotalTurn(
        remainingBefore: 40,
        score: 40,
        doubleOut: true,
        finishedWithDouble: true,
      );
      expect(result.isCheckout, true);
    });

    test('remaining 1 with double-out is bust', () {
      final result = DartsRules.evaluateTotalTurn(
        remainingBefore: 21,
        score: 20,
        doubleOut: true,
        finishedWithDouble: false,
      );
      expect(result.isBust, true);
    });
  });

  group('DartsRules.evaluateDartByDartTurn', () {
    test('double finish with double-out is checkout', () {
      final result = DartsRules.evaluateDartByDartTurn(
        remainingBefore: 40,
        darts: [const DartThrow(multiplier: 2, value: 20)],
        doubleOut: true,
      );
      expect(result.isCheckout, true);
    });

    test('single finish with double-out is bust', () {
      final result = DartsRules.evaluateDartByDartTurn(
        remainingBefore: 20,
        darts: [const DartThrow(multiplier: 1, value: 20)],
        doubleOut: true,
      );
      expect(result.isBust, true);
    });

    test('bull 50 finish with double-out is checkout', () {
      final result = DartsRules.evaluateDartByDartTurn(
        remainingBefore: 50,
        darts: [const DartThrow(multiplier: 2, value: 25)],
        doubleOut: true,
      );
      expect(result.isCheckout, true);
    });

    test('multiple darts accumulate correctly', () {
      final result = DartsRules.evaluateDartByDartTurn(
        remainingBefore: 100,
        darts: [
          const DartThrow(multiplier: 3, value: 20), // 60
          const DartThrow(multiplier: 1, value: 20), // 20
          const DartThrow(multiplier: 1, value: 20), // 20 → 0
        ],
        doubleOut: false,
      );
      expect(result.isCheckout, true);
    });
  });
}
