import 'package:flutter/foundation.dart';

@immutable
class DartThrow {
  const DartThrow({
    required this.multiplier,
    required this.value,
  });

  final int multiplier; // 1=single, 2=double, 3=triple
  final int value;      // 0=miss, 1-20=segment, 25=bull

  int get points => multiplier * value;

  bool get isDouble => multiplier == 2;
  bool get isBullseye => multiplier == 2 && value == 25; // double bull = 50
  bool get isMiss => value == 0;

  factory DartThrow.fromJson(Map<String, dynamic> json) => DartThrow(
        multiplier: json['multiplier'] as int,
        value: json['value'] as int,
      );

  Map<String, dynamic> toJson() => {
        'multiplier': multiplier,
        'value': value,
      };

  @override
  String toString() {
    if (isMiss) return 'Miss';
    if (value == 25 && multiplier == 1) return 'Bull (25)';
    if (value == 25 && multiplier == 2) return 'Bull (50)';
    final prefix = multiplier == 1
        ? 'S'
        : multiplier == 2
            ? 'D'
            : 'T';
    return '$prefix$value';
  }
}
