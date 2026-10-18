import "package:another_mine_common/model/game_difficulty.dart";

/// The URL of a game, shared by the clients so a link opens the same board in
/// either: `/game/<width>/<height>/<mines>`.
abstract class GameRoutes {
  GameRoutes._();

  static const String widthParam = "width";
  static const String heightParam = "height";
  static const String minesParam = "mines";

  /// The route pattern, for a router.
  static const String pattern = "/game/:$widthParam/:$heightParam/:$minesParam";

  static const String settings = "/settings";
  static const String scores = "/scores";
  static const String custom = "/custom";

  /// The path that plays [difficulty].
  static String game(GameDifficulty difficulty) =>
      "/game/${difficulty.width}/${difficulty.height}/${difficulty.mines}";

  /// The difficulty named by the route parameters, falling back to beginner for
  /// anything missing or not a number.
  static GameDifficulty difficultyFrom(Map<String, String> parameters) {
    int read(String name, int fallback) =>
        int.tryParse(parameters[name] ?? "") ?? fallback;

    return GameDifficulty.custom(
      width: read(widthParam, GameDifficulty.beginner.width),
      height: read(heightParam, GameDifficulty.beginner.height),
      mines: read(minesParam, GameDifficulty.beginner.mines),
    );
  }
}
