import "package:another_mine_common/scores/score_category.dart";

/// Another Mine's identity on the SpaceCloud and scores servers.
class OnlineConfig {
  const OnlineConfig._();

  /// Public, like Delta-V's: it names the game, not a person.
  static const String publisherKey = "bba6405e-965e-4d74-88f6-8e8aa17be176";
  static const String publisherName = "WillShex Limited";
  static const String applicationName = "Another Mine";
  static const int applicationId = 6285245378723840;

  static const Map<ScoreCategory, int> _categoryIds = {
    ScoreCategory.beginner: 6331305365078016,
    ScoreCategory.intermediate: 6228069652103168,
    ScoreCategory.expert: 6306066258198528,
    ScoreCategory.medium: 6307370342809600,
    ScoreCategory.hard: 6229745385603072,
  };

  /// The category's id on the scores service, or null if it is not kept online.
  static int? categoryId(ScoreCategory category) => _categoryIds[category];
}
