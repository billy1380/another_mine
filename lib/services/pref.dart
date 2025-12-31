import "package:logging/logging.dart";
import "package:shared_preferences/shared_preferences.dart";

class Pref {
  static final Logger _log = Logger("Perf");
  late final String _prefix;
  late final SharedPreferences _sharedPreferences;

  static const String keyAnimate = "animate";
  static const String keyScoresRetained = "scoresRetained";
  static const String keyRemoteScoresEnabled = "remoteHighScoresEnabled";
  static const String keyDefaultCountry = "defaultCountry";
  static const String keyCustomBgEnabled = "customBackgroundColourEnabled";
  static const String keyCustomBgColor = "customBackgroundColour";
  static const String keyAutoSolverSettingName = "autoSolver";

  static Pref? _one;

  static Pref get service => _one ??= Pref();
  bool _init = false;
  bool get isInitialized => _init;

  Future<bool> init(String prefix) async {
    if (_init) {
      _log.warning("Attempted to reinit pref service; not possible: skipping!");
    } else {
      _sharedPreferences = await SharedPreferences.getInstance();
      _prefix = prefix;
      _init = true;
    }

    return _init;
  }

  String? getString(String name) => _sharedPreferences.getString(_key(name));

  Future<bool> setString(String name, String? value) async {
    bool done = false;
    if (value == null) {
      done = await _sharedPreferences.remove(_key(name));
    } else {
      done = await _sharedPreferences.setString(_key(name), value);
    }

    return done;
  }

  bool? getBool(String name) => _sharedPreferences.getBool(_key(name));
  Future<bool> setBool(String name, bool? value) async {
    bool done = false;
    if (value == null) {
      done = await _sharedPreferences.remove(_key(name));
    } else {
      done = await _sharedPreferences.setBool(_key(name), value);
    }

    return done;
  }

  int? getInt(String name) => _sharedPreferences.getInt(_key(name));
  Future<bool> setInt(String name, int? value) async {
    bool done = false;
    if (value == null) {
      done = await _sharedPreferences.remove(_key(name));
    } else {
      done = await _sharedPreferences.setInt(_key(name), value);
    }

    return done;
  }

  bool get animate => getBool(keyAnimate) ?? true;
  int get scoresRetained => getInt(keyScoresRetained) ?? 20;
  bool get remoteScoresEnabled => getBool(keyRemoteScoresEnabled) ?? false;
  String get defaultCountry => getString(keyDefaultCountry) ?? "United Kingdom";
  bool get customBgEnabled => getBool(keyCustomBgEnabled) ?? false;
  int? get customBgColor => getInt(keyCustomBgColor);
  bool get autoSolverEnabled => getBool(keyAutoSolverSettingName) ?? false;

  String _key(String name) => "$_prefix$name";
}
