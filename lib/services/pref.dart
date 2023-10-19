import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pref {
  static final Logger _log = Logger("Perf");
  late final String _prefix;
  late final SharedPreferences _sharedPreferences;

  static Pref? _one;

  static Pref get service => _one ??= Pref();
  bool _init = false;

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

  bool? getBool(String name) =>
      _sharedPreferences.getString(_key(name)) == true.toString();
  Future<bool> setBool(String name, bool? value) async {
    bool done = false;
    if (value == null) {
      done = await _sharedPreferences.remove(_key(name));
    } else {
      done = await _sharedPreferences.setString(_key(name), value.toString());
    }

    return done;
  }

  String _key(String name) => "$_prefix$name";
}
