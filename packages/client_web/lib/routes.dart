import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_web/ui/screens/custom_game_screen.dart";
import "package:another_mine_web/ui/screens/game_screen.dart";
import "package:another_mine_web/ui/screens/scores_screen.dart";
import "package:another_mine_web/ui/screens/settings_screen.dart";
import "package:jaspr_router/jaspr_router.dart";

/// Routes for the Another Mine web client, for the app itself or for mounting
/// into a host's router.
class AnotherMineWebRoutes {
  AnotherMineWebRoutes._();

  /// The routes of the game.
  ///
  /// - [prefix]: where they are mounted, for example `"/mine"`.
  /// - [relative]: strip the leading slash, for subroutes of a parent route.
  /// - [useLayout]: wrap screens in the standalone sidebar and header. Hosts
  ///   with their own shell pass false.
  static List<Route> routes({
    String prefix = "",
    bool relative = false,
    bool useLayout = true,
  }) {
    // Under a parent route the prefix is the parent's, and the path is
    // relative to it.
    String path(String full) =>
        relative ? full.replaceFirst(RegExp(r"^/+"), "") : "$prefix$full";

    return [
      Route(
        path: relative ? "" : (prefix.isEmpty ? "/" : prefix),
        redirect: (context, state) =>
            "$prefix${GameRoutes.game(Provider.pref.difficulty)}",
      ),
      Route(
        path: path(GameRoutes.pattern),
        builder: (context, state) => GameScreen(
          difficulty: GameRoutes.difficultyFrom(state.params),
          useLayout: useLayout,
        ),
      ),
      Route(
        path: path(GameRoutes.custom),
        builder: (context, state) => CustomGameScreen(
          useLayout: useLayout,
          basePath: prefix,
          onStart: (difficulty) =>
              Router.of(context).push("$prefix${GameRoutes.game(difficulty)}"),
        ),
      ),
      Route(
        path: path(GameRoutes.settings),
        builder: (context, state) =>
            SettingsScreen(useLayout: useLayout, basePath: prefix),
      ),
      Route(
        path: path(GameRoutes.scores),
        builder: (context, state) =>
            ScoresScreen(useLayout: useLayout, basePath: prefix),
      ),
    ];
  }
}
