import 'package:shared_preferences/shared_preferences.dart';

class Pref {
  late final String _prefix;
  late final SharedPreferences _sharedPreferences;

  static Pref? _one;

  static Pref get service => _one ??= Pref();

  Future<bool> init(String prefix) async {
    _sharedPreferences = await SharedPreferences.getInstance();
    _prefix = prefix;

    return true;
  }

  String? getString(String name) => _sharedPreferences.getString(_key(name));

  void setString(String name, String? value) {
    if (value == null) {
      _sharedPreferences.remove(_key(name));
    } else {
      _sharedPreferences.setString(_key(name), value);
    }
  }

  String _key(String name) => "$_prefix$name";
}
