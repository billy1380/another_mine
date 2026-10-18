import "package:another_mine_common/another_mine_common.dart";
import "package:web/web.dart" as web;

/// Keeps the game's settings in the browser's `localStorage`.
class LocalStoragePrefStorage extends PrefStorage {
  @override
  Future<void> init() async {}

  @override
  String? getString(String key) => _read(key);

  @override
  bool? getBool(String key) {
    final String? value = _read(key);
    return value == null ? null : value == "true";
  }

  @override
  int? getInt(String key) => int.tryParse(_read(key) ?? "");

  @override
  Future<bool> setString(String key, String value) async => _write(key, value);

  @override
  Future<bool> setBool(String key, bool value) async =>
      _write(key, value.toString());

  @override
  Future<bool> setInt(String key, int value) async =>
      _write(key, value.toString());

  @override
  Future<bool> remove(String key) async {
    try {
      web.window.localStorage.removeItem(key);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Storage can be missing or full (private browsing, blocked cookies), the
  // game carries on with its defaults then.
  String? _read(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  bool _write(String key, String value) {
    try {
      web.window.localStorage.setItem(key, value);
      return true;
    } catch (_) {
      return false;
    }
  }
}
