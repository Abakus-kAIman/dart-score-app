import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Desktop/mobile backend — stores plain JSON files in the app support directory.
///
/// Windows: C:\Users\{user}\AppData\Roaming\com.dartscoreapp\dart_score_app\
/// macOS:   ~/Library/Application Support/com.dartscoreapp.dartScoreApp/
/// Linux:   ~/.local/share/dart_score_app/
class StorageBackend {
  final Directory _dir;
  StorageBackend._(this._dir);

  static Future<StorageBackend> create() async {
    final dir = await getApplicationSupportDirectory();
    if (!dir.existsSync()) await dir.create(recursive: true);
    return StorageBackend._(dir);
  }

  File _file(String key) => File('${_dir.path}/$key.json');

  Future<void> write(String key, String value) =>
      _file(key).writeAsString(value);

  Future<String?> read(String key) async {
    final f = _file(key);
    if (!f.existsSync()) return null;
    return f.readAsString();
  }

  Future<void> delete(String key) async {
    final f = _file(key);
    if (f.existsSync()) await f.delete();
  }

  /// Human-readable path shown in the UI so users know where files live.
  String get dataLocation => _dir.path;
}
