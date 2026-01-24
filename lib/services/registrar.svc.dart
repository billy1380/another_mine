// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of "registrar.dart";

// **************************************************************************
// RegistrarGenerator
// **************************************************************************

class Registrar {
  Registrar._();
  static Future<void> init({
    void Function(Type type)? onChange,
  }) async {
    ServiceDiscovery.instance.register<Pref>(Pref("another_mine_"));
    await ServiceDiscovery.instance.init(
      onChange: onChange,
    );
  }
}
