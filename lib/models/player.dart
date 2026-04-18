import 'package:flutter/foundation.dart';

@immutable
class Player {
  const Player({required this.id, required this.name});

  final String id;
  final String name;

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  Player copyWith({String? id, String? name}) =>
      Player(id: id ?? this.id, name: name ?? this.name);
}
