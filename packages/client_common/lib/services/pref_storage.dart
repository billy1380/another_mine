/// Where [Pref] keeps its values.
///
/// Each client supplies its own, for example `shared_preferences` on Flutter
/// and `localStorage` on the web. Values are read synchronously once [init] has
/// completed.
abstract class PrefStorage {
  const PrefStorage();

  /// Opens the underlying store. Called once before any other member.
  Future<void> init();

  String? getString(String key);
  bool? getBool(String key);
  int? getInt(String key);

  Future<bool> setString(String key, String value);
  Future<bool> setBool(String key, bool value);
  Future<bool> setInt(String key, int value);

  Future<bool> remove(String key);
}

/// A [PrefStorage] that keeps everything in memory, for tests and for hosts
/// that do not want anything persisted.
class InMemoryPrefStorage extends PrefStorage {
  final Map<String, Object> _values;

  /// Starts with [initial] values, if any.
  InMemoryPrefStorage([Map<String, Object>? initial]) : _values = {...?initial};

  @override
  Future<void> init() async {}

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async => _values.remove(key) != null;
}
