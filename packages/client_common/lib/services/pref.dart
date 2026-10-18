import "dart:async";

import "package:another_mine_common/model/auto_solver_type.dart";
import "package:another_mine_common/model/colour.dart";
import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/services/pref_storage.dart";
import "package:logging/logging.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

class Pref extends BasicService {
  static final Logger _log = Logger("Perf");

  final String _prefix;
  final PrefStorage _storage;

  static const String keyAnimate = "animate";
  static const String keyScoresRetained = "scoresRetained";
  static const String keyRemoteScoresEnabled = "remoteHighScoresEnabled";
  static const String keyDefaultCountry = "defaultCountry";
  static const String keyCustomBgEnabled = "customBackgroundColourEnabled";
  static const String keyCustomBgColor = "customBackgroundColour";
  static const String keyAutoSolverSettingName = "autoSolver";
  static const String keyAutoSolverType = "autoSolverType";

  static const Colour defaultBackgroundColour = Colour.fromARGB(
    0xff,
    0x2e,
    0x34,
    0x36,
  );

  Pref(this._prefix, this._storage);

  @override
  Future<void> onInit() async {
    _log.info("Created Pref service with prefix: $_prefix.");

    await _storage.init();
  }

  String? getString(String name) => _storage.getString(_key(name));

  Future<bool> setString(String name, String? value) async {
    bool done = false;
    if (value == null) {
      done = await _storage.remove(_key(name));
    } else {
      done = await _storage.setString(_key(name), value);
    }

    return done;
  }

  bool? getBool(String name) => _storage.getBool(_key(name));
  Future<bool> setBool(String name, bool? value) async {
    bool done = false;
    if (value == null) {
      done = await _storage.remove(_key(name));
    } else {
      done = await _storage.setBool(_key(name), value);
    }

    return done;
  }

  int? getInt(String name) => _storage.getInt(_key(name));
  Future<bool> setInt(String name, int? value) async {
    bool done = false;
    if (value == null) {
      done = await _storage.remove(_key(name));
    } else {
      done = await _storage.setInt(_key(name), value);
    }

    return done;
  }

  bool get animate => getBool(keyAnimate) ?? true;
  int get scoresRetained => getInt(keyScoresRetained) ?? 20;
  bool get remoteScoresEnabled => getBool(keyRemoteScoresEnabled) ?? false;
  String get defaultCountry => getString(keyDefaultCountry) ?? "United Kingdom";
  bool get customBgEnabled => getBool(keyCustomBgEnabled) ?? false;
  int get customBgColor =>
      getInt(keyCustomBgColor) ?? defaultBackgroundColour.argb;
  bool get autoSolverEnabled => getBool(keyAutoSolverSettingName) ?? false;
  AutoSolverType get autoSolverType => AutoSolverType.values.firstWhere(
    (e) => e.name == getString(keyAutoSolverType),
    orElse: () => AutoSolverType.simple,
  );

  Colour get effectiveCustomBgColor =>
      customBgEnabled ? Colour(customBgColor) : defaultBackgroundColour;

  GameDifficulty get difficulty {
    int width = getInt("width") ?? GameDifficulty.beginner.width;
    int height = getInt("height") ?? GameDifficulty.beginner.height;
    int mines = getInt("mines") ?? GameDifficulty.beginner.mines;

    return GameDifficulty.custom(width: width, height: height, mines: mines);
  }

  String _key(String name) => "$_prefix$name";

  @override
  void onReset() {}
}
