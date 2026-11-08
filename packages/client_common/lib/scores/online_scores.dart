import "package:another_mine_common/dialogs/another_mine_dialogs.dart";
import "package:another_mine_common/services/pref.dart";
import "package:another_mine_common/services/provider.dart";
import "package:another_mine_common/strings.dart";
import "package:willshex_online_player/willshex_online_player.dart";
import "package:willshex_space_cloud/willshex_space_cloud.dart";

export "package:willshex_online_player/willshex_online_player.dart"
    show
        OnlinePlayer,
        OnlineScores,
        countryName,
        flagOf,
        serviceImage,
        serviceName;

/// The online player, kept in [Pref].
class PrefOnlinePlayerStore implements OnlinePlayerStore {
  const PrefOnlinePlayerStore();

  @override
  OnlinePlayer get player {
    final Pref pref = Provider.pref;

    return OnlinePlayer(
      pref.playerName,
      pref.playerService,
      pref.defaultCountry,
    );
  }

  @override
  bool get isEnabled => Provider.pref.remoteScoresEnabled;

  @override
  Future<void> savePlayer(OnlinePlayer player) async {
    final Pref pref = Provider.pref;
    await pref.setString(Pref.keyPlayerName, player.name);
    await pref.setString(Pref.keyPlayerService, player.service.name);
    await pref.setString(
      Pref.keyDefaultCountry,
      fromCountryToString(player.country),
    );
  }

  @override
  Future<void> setEnabled(bool enabled) =>
      Provider.pref.setBool(Pref.keyRemoteScoresEnabled, enabled);
}

/// Another Mine's online scores: the shared player flow, kept in [Pref] and
/// asked through the game's own dialogs.
OnlineScores get onlineScores => OnlineScores(
  store: const PrefOnlinePlayerStore(),
  ask: AnotherMineDialogs.ask,
  options: const OnlinePlayerOptions(message: Strings.onlinePlayerMessage),
);
