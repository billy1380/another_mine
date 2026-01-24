import "dart:async";

import "package:another_mine/model/auto_solver_type.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:logging/logging.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

class Pref extends BasicService {
  static final Logger _log = Logger("Perf");

  final String _prefix;
  late final SharedPreferences _sharedPreferences;

  static const String keyAnimate = "animate";
  static const String keyScoresRetained = "scoresRetained";
  static const String keyRemoteScoresEnabled = "remoteHighScoresEnabled";
  static const String keyDefaultCountry = "defaultCountry";
  static const String keyCustomBgEnabled = "customBackgroundColourEnabled";
  static const String keyCustomBgColor = "customBackgroundColour";
  static const String keyAutoSolverSettingName = "autoSolver";
  static const String keyAutoSolverType = "autoSolverType";

  Pref(this._prefix);

  @override
  Future<void> onInit() async {
    _log.info("Created Pref service with prefix: $_prefix.");

    _sharedPreferences = await SharedPreferences.getInstance();
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
  AutoSolverType get autoSolverType => AutoSolverType.values.firstWhere(
        (e) => e.name == getString(keyAutoSolverType),
        orElse: () => AutoSolverType.simple,
      );

  GameDifficulty get difficulty {
    int width = getInt("width") ?? GameDifficulty.beginner.width;
    int height = getInt("height") ?? GameDifficulty.beginner.height;
    int mines = getInt("mines") ?? GameDifficulty.beginner.mines;

    return GameDifficulty.custom(
      width: width,
      height: height,
      mines: mines,
    );
  }

  String _key(String name) => "$_prefix$name";

  @override
  void onReset() {}
}
