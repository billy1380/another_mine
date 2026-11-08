import "package:another_mine_common/another_mine_common.dart";
import "package:flutter/widgets.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

/// Offers to keep the score of the game that was just won, if it places among
/// the best of its category. Does nothing for a game that is not kept (lost,
/// played by the solver, or not good enough).
///
/// The question is a dialog request, drawn by the host if the game is in one
/// that draws dialogs and by the game itself if not.
Future<void> offerToKeepScore(BuildContext context, GameState state) async {
  // a host that has not started the game's services keeps no scores
  if (!ServiceDiscovery.instance.isRegistered<ScoreKeeper>()) return;

  final ScoreKeeper keeper = Provider.scoreKeeper;
  final WonGame? game = keeper.wonGame(state);
  if (game == null) return;

  final int? place = await keeper.rankOf(game);
  if (place == null) return;

  final String? name = await ScoreDialogs.askName(
    game,
    place,
    initialName: Provider.pref.playerName,
  );

  if (name != null) await keeper.keep(game, name);
}
