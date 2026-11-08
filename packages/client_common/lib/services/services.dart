import "package:another_mine_common/scores/score_keeper.dart";
import "package:another_mine_common/services/pref.dart";
import "package:another_mine_common/services/pref_storage.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

/// The prefix of the keys the game keeps its settings under.
const String prefPrefix = "another_mine_";

/// Where scores are kept in the browser's file system when the host gives no
/// path.
const String webScoresPath = "another_mine/scores";

const bool _isWeb = bool.fromEnvironment("dart.library.js_interop");

/// Registers and opens the game's own [Pref] and [ScoreKeeper] services on
/// [storage].
///
/// Scores are kept in a folder at [scoresPath]; on the web a name in the
/// browser's file system is used if there is none. A host that gives no path
/// on a device keeps no scores.
///
/// Only this game's services are touched, other services in the discovery
/// registry belong to the host and are left alone. Safe to call again, the
/// first registration wins.
Future<void> initServices(PrefStorage storage, {String? scoresPath}) async {
  final ServiceDiscovery discovery = ServiceDiscovery.instance;
  if (!discovery.isRegistered<Pref>()) {
    discovery.register<Pref>(Pref(prefPrefix, storage));
  }

  final Pref pref = discovery.resolve<Pref>();
  await pref.init();

  if (!discovery.isRegistered<ScoreKeeper>()) {
    discovery.register<ScoreKeeper>(
      ScoreKeeper(scoresPath ?? (_isWeb ? webScoresPath : null), pref),
    );
  }

  await discovery.resolve<ScoreKeeper>().init();
}
