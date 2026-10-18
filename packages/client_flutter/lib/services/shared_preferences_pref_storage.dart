import "package:another_mine_common/another_mine_common.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Keeps the game's settings in `shared_preferences`.
class SharedPreferencesPrefStorage extends PrefStorage {
  late final SharedPreferences _preferences;

  @override
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  bool? getBool(String key) => _preferences.getBool(key);

  @override
  int? getInt(String key) => _preferences.getInt(key);

  @override
  Future<bool> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<bool> setBool(String key, bool value) =>
      _preferences.setBool(key, value);

  @override
  Future<bool> setInt(String key, int value) => _preferences.setInt(key, value);

  @override
  Future<bool> remove(String key) => _preferences.remove(key);
}
