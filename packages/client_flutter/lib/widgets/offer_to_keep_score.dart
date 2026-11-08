import "dart:async";

import "package:another_mine_common/another_mine_common.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter/widgets.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

/// Sends the game that was just won online if online scores are on, and offers
/// to keep its score locally if it places among the best of its category. Does nothing for a game that is not kept (lost,
/// played by the solver, or not good enough).
///
/// The question is a dialog request, drawn by the host if the game is in one
/// that draws dialogs and by the game itself if not.
Future<void> offerToKeepScore(BuildContext context, GameState state) async {
  // a host that has not started the game's services keeps no scores
  if (!ServiceDiscovery.instance.isRegistered<ScoreKeeper>()) return;

  final ScoreKeeper keeper = Provider.scoreKeeper;
  final WonGame? game = keeper.wonGame(
    state,
    events: context.read<GameBloc>().recorder.events,
  );
  if (game == null) return;

  // online first: it needs neither a place nor a name, and never holds this up
  unawaited(keeper.submitOnline(game));

  final int? place = await keeper.rankOf(game);
  if (place == null) return;

  final String? name = await ScoreDialogs.askName(
    game,
    place,
    initialName: Provider.pref.playerName,
    // with online scores on the player is known, so the name is not asked again
    askForName: !Provider.pref.remoteScoresEnabled,
  );

  if (name != null) await keeper.keep(game, name);
}
