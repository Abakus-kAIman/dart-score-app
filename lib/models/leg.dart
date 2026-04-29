import 'package:flutter/foundation.dart';
import 'turn.dart';

@immutable
class Leg {
  const Leg({
    required this.id,
    required this.legNumber,
    required this.turns,
    this.winnerId,
    this.startPlayerIndex = 0,
  });

  final String id;
  final int legNumber;
  final String? winnerId;
  final List<Turn> turns;
  final int startPlayerIndex;

  bool get isComplete => winnerId != null;

  factory Leg.fromJson(Map<String, dynamic> json) => Leg(
        id: json['id'] as String,
        legNumber: json['legNumber'] as int,
        winnerId: json['winnerId'] as String?,
        startPlayerIndex: json['startPlayerIndex'] as int? ?? 0,
        turns: (json['turns'] as List<dynamic>)
            .map((t) => Turn.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'legNumber': legNumber,
        'winnerId': winnerId,
        'startPlayerIndex': startPlayerIndex,
        'turns': turns.map((t) => t.toJson()).toList(),
      };

  Leg copyWith({
    String? id,
    int? legNumber,
    String? winnerId,
    List<Turn>? turns,
    bool clearWinner = false,
    int? startPlayerIndex,
  }) =>
      Leg(
        id: id ?? this.id,
        legNumber: legNumber ?? this.legNumber,
        winnerId: clearWinner ? null : (winnerId ?? this.winnerId),
        turns: turns ?? this.turns,
        startPlayerIndex: startPlayerIndex ?? this.startPlayerIndex,
      );
}
