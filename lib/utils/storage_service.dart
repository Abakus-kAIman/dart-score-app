import 'dart:convert';

import '../models/match.dart';

// Conditional import: on web → shared_preferences, on desktop → dart:io files.
import '_storage_backend_io.dart'
    if (dart.library.html) '_storage_backend_web.dart';

class StorageService {
  static StorageService? _instance;
  late final StorageBackend _backend;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _instance!._backend = await StorageBackend.create();
    }
    return _instance!;
  }

  /// Where data is physically stored. Useful to show users on desktop.
  String get dataLocation => _backend.dataLocation;

  Future<void> saveActiveMatch(DartsMatch match) =>
      _backend.write('active_match', jsonEncode(match.toJson()));

  Future<DartsMatch?> loadActiveMatch() async {
    final raw = await _backend.read('active_match');
    if (raw == null) return null;
    try {
      return DartsMatch.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveMatch() => _backend.delete('active_match');

  Future<void> saveCompletedMatch(DartsMatch match) async {
    final matches = await loadCompletedMatches();
    matches.insert(0, match);
    await _backend.write(
      'match_history',
      jsonEncode(matches.map((m) => m.toJson()).toList()),
    );
  }

  Future<List<DartsMatch>> loadCompletedMatches() async {
    final raw = await _backend.read('match_history');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => DartsMatch.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
