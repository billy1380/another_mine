import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/scores/score_category.dart";

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

  /// The optional query parameter of [scores] that picks the tab: `?tab=expert`.
  static const String tabParam = "tab";

  /// The path of the scores page on [category]'s tab.
  static String scoresPath(ScoreCategory category) =>
      "$scores?$tabParam=${category.slug}";

  /// The tab named by the query [parameters], beginner if there is none or it
  /// is not one.
  static ScoreCategory tabFrom(Map<String, String> parameters) =>
      ScoreCategory.fromSlug(parameters[tabParam]) ?? ScoreCategory.beginner;

  static const String scoreParam = "id";

  /// The route pattern of the replay of an online score.
  static const String score = "/score/:$scoreParam";

  /// The path that replays the online score [id].
  static String scorePath(int id) => "/score/$id";

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
