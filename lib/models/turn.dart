import 'package:flutter/foundation.dart';
import 'dart_throw.dart';

enum TurnMode { total, dartByDart }

@immutable
class Turn {
  const Turn({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.turnIndex,
    required this.mode,
    required this.score,
    required this.remainingBefore,
    required this.remainingAfter,
    required this.isBust,
    required this.isCheckout,
    this.darts,
  });

  final String id;
  final String playerId;
  final String playerName;
  final int turnIndex;
  final TurnMode mode;
  final List<DartThrow>? darts;
  final int score;
  final int remainingBefore;
  final int remainingAfter;
  final bool isBust;
  final bool isCheckout;

  factory Turn.fromJson(Map<String, dynamic> json) => Turn(
        id: json['id'] as String,
        playerId: json['playerId'] as String,
        playerName: json['playerName'] as String,
        turnIndex: json['turnIndex'] as int,
        mode: TurnMode.values.byName(json['mode'] as String),
        score: json['score'] as int,
        remainingBefore: json['remainingBefore'] as int,
        remainingAfter: json['remainingAfter'] as int,
        isBust: json['isBust'] as bool,
        isCheckout: json['isCheckout'] as bool,
        darts: (json['darts'] as List<dynamic>?)
            ?.map((d) => DartThrow.fromJson(d as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerId': playerId,
        'playerName': playerName,
        'turnIndex': turnIndex,
        'mode': mode.name,
        'score': score,
        'remainingBefore': remainingBefore,
        'remainingAfter': remainingAfter,
        'isBust': isBust,
        'isCheckout': isCheckout,
        'darts': darts?.map((d) => d.toJson()).toList(),
      };
}
