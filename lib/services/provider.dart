import "package:another_mine/services/pref.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

part "provider.svc.dart";

@DiscoveryProvider()
abstract class Trigger {
  Trigger._();
}
