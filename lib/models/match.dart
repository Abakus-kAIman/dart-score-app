import 'package:flutter/foundation.dart';
import 'player.dart';
import 'leg.dart';

@immutable
class DartsMatch {
  const DartsMatch({
    required this.id,
    required this.createdAt,
    required this.players,
    required this.startingScore,
    required this.doubleOut,
    required this.legsToWin,
    required this.currentLegIndex,
    required this.completed,
    required this.legs,
    this.winnerId,
  });

  final String id;
  final DateTime createdAt;
  final List<Player> players;
  final int startingScore;
  final bool doubleOut;
  final int legsToWin;
  final int currentLegIndex;
  final bool completed;
  final String? winnerId;
  final List<Leg> legs;

  Leg get currentLeg => legs[currentLegIndex];

  Map<String, int> get legWins {
    final wins = <String, int>{};
    for (final player in players) {
      wins[player.id] = 0;
    }
    for (final leg in legs) {
      if (leg.winnerId != null) {
        wins[leg.winnerId!] = (wins[leg.winnerId!] ?? 0) + 1;
      }
    }
    return wins;
  }

  factory DartsMatch.fromJson(Map<String, dynamic> json) => DartsMatch(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        players: (json['players'] as List<dynamic>)
            .map((p) => Player.fromJson(p as Map<String, dynamic>))
            .toList(),
        startingScore: json['startingScore'] as int,
        doubleOut: json['doubleOut'] as bool,
        legsToWin: json['legsToWin'] as int,
        currentLegIndex: json['currentLegIndex'] as int,
        completed: json['completed'] as bool,
        winnerId: json['winnerId'] as String?,
        legs: (json['legs'] as List<dynamic>)
            .map((l) => Leg.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'players': players.map((p) => p.toJson()).toList(),
        'startingScore': startingScore,
        'doubleOut': doubleOut,
        'legsToWin': legsToWin,
        'currentLegIndex': currentLegIndex,
        'completed': completed,
        'winnerId': winnerId,
        'legs': legs.map((l) => l.toJson()).toList(),
      };

  DartsMatch copyWith({
    String? id,
    DateTime? createdAt,
    List<Player>? players,
    int? startingScore,
    bool? doubleOut,
    int? legsToWin,
    int? currentLegIndex,
    bool? completed,
    String? winnerId,
    List<Leg>? legs,
    bool clearWinner = false,
  }) =>
      DartsMatch(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        players: players ?? this.players,
        startingScore: startingScore ?? this.startingScore,
        doubleOut: doubleOut ?? this.doubleOut,
        legsToWin: legsToWin ?? this.legsToWin,
        currentLegIndex: currentLegIndex ?? this.currentLegIndex,
        completed: completed ?? this.completed,
        winnerId: clearWinner ? null : (winnerId ?? this.winnerId),
        legs: legs ?? this.legs,
      );
}
