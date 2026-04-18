import 'package:flutter/foundation.dart';
import 'turn.dart';

@immutable
class Leg {
  const Leg({
    required this.id,
    required this.legNumber,
    required this.turns,
    this.winnerId,
  });

  final String id;
  final int legNumber;
  final String? winnerId;
  final List<Turn> turns;

  bool get isComplete => winnerId != null;

  factory Leg.fromJson(Map<String, dynamic> json) => Leg(
        id: json['id'] as String,
        legNumber: json['legNumber'] as int,
        winnerId: json['winnerId'] as String?,
        turns: (json['turns'] as List<dynamic>)
            .map((t) => Turn.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'legNumber': legNumber,
        'winnerId': winnerId,
        'turns': turns.map((t) => t.toJson()).toList(),
      };

  Leg copyWith({
    String? id,
    int? legNumber,
    String? winnerId,
    List<Turn>? turns,
    bool clearWinner = false,
  }) =>
      Leg(
        id: id ?? this.id,
        legNumber: legNumber ?? this.legNumber,
        winnerId: clearWinner ? null : (winnerId ?? this.winnerId),
        turns: turns ?? this.turns,
      );
}
