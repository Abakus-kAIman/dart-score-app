import 'package:shared_preferences/shared_preferences.dart';

/// Web backend — uses browser localStorage via shared_preferences.
class StorageBackend {
  final SharedPreferences _prefs;
  StorageBackend._(this._prefs);

  static Future<StorageBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageBackend._(prefs);
  }

  Future<void> write(String key, String value) =>
      _prefs.setString(key, value);

  Future<String?> read(String key) async => _prefs.getString(key);

  Future<void> delete(String key) => _prefs.remove(key);

  /// Web has no visible file path.
  String get dataLocation => 'Browser localStorage';
}
