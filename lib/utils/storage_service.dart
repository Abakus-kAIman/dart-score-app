import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match.dart';

class StorageService {
  static const _matchesKey = 'completed_matches';
  static const _activeMatchKey = 'active_match';

  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  Future<void> saveActiveMatch(DartsMatch match) async {
    await _prefs.setString(_activeMatchKey, jsonEncode(match.toJson()));
  }

  Future<DartsMatch?> loadActiveMatch() async {
    final raw = _prefs.getString(_activeMatchKey);
    if (raw == null) return null;
    try {
      return DartsMatch.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveMatch() async {
    await _prefs.remove(_activeMatchKey);
  }

  Future<void> saveCompletedMatch(DartsMatch match) async {
    final matches = await loadCompletedMatches();
    matches.insert(0, match);
    final encoded = jsonEncode(matches.map((m) => m.toJson()).toList());
    await _prefs.setString(_matchesKey, encoded);
  }

  Future<List<DartsMatch>> loadCompletedMatches() async {
    final raw = _prefs.getString(_matchesKey);
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
