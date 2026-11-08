import "package:another_mine_common/model/game_difficulty.dart";

/// The scores categories of Another Mine.
///
/// The three presets keep their own category. Any other board is ranked by its
/// mine density, `mines / (width x height)`, against the presets: below
/// Beginner's it is [easy], below Intermediate's [medium], and anything denser
/// is [hard] (there is no category past Expert). The exact board is recorded on
/// each score, so nothing is lost by sharing a category.
enum ScoreCategory {
  beginner(1, "Beginner"),
  intermediate(2, "Intermediate"),
  expert(3, "Expert"),
  easy(4, "Custom Easy"),
  medium(5, "Custom Medium"),
  hard(6, "Custom Hard");

  /// The id the category has in the local store. Online, categories are found
  /// by [label] and the game, never by this.
  final int localId;

  /// The category's name, here and on the scores service.
  final String label;

  const ScoreCategory(this.localId, this.label);

  /// Whether scores of this category go online. Custom Easy games are local only.
  bool get isOnline => this != easy;

  static ScoreCategory forDifficulty(GameDifficulty difficulty) {
    switch (difficulty.name) {
      case beginnerName:
        return beginner;
      case intermediateName:
        return intermediate;
      case expertName:
        return expert;
    }

    final double density = difficulty.difficultyFactor;

    if (density < GameDifficulty.beginner.difficultyFactor) return easy;
    if (density < GameDifficulty.intermediate.difficultyFactor) return medium;

    return hard;
  }

  static ScoreCategory? forLocalId(int? id) {
    for (final ScoreCategory category in values) {
      if (category.localId == id) return category;
    }

    return null;
  }
}
