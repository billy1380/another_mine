import "package:another_mine_common/services/pref.dart";
import "package:another_mine_common/services/pref_storage.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

/// The prefix of the keys the game keeps its settings under.
const String prefPrefix = "another_mine_";

/// Registers and opens the game's own [Pref] service on [storage].
///
/// Only this game's service is touched, other services in the discovery
/// registry belong to the host and are left alone. Safe to call again, the
/// first registration wins.
Future<void> initServices(PrefStorage storage) async {
  final ServiceDiscovery discovery = ServiceDiscovery.instance;
  if (!discovery.isRegistered<Pref>()) {
    discovery.register<Pref>(Pref(prefPrefix, storage));
  }

  await discovery.resolve<Pref>().init();
}
