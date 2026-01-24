import "package:another_mine/services/pref.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

part "registrar.svc.dart";

@DiscoveryRegistrar()
abstract class Trigger {
  Trigger._();
}
