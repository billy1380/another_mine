import "dart:convert";

import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/scores/score_category.dart";

/// Who played a game.
enum Solver { human, simple, probability }

/// A finished, won game as the scores list shows it.
class LocalScore {
  /// The score's id in the local store, or null for one not stored yet. What a
  /// score is deleted by.
  final int? id;
  final String name;
  final int seconds;
  final ScoreCategory category;
  final int width;
  final int height;
  final int mines;
  final Solver solver;
  final DateTime when;

  const LocalScore({
    this.id,
    required this.name,
    required this.seconds,
    required this.category,
    required this.width,
    required this.height,
    required this.mines,
    required this.solver,
    required this.when,
  });

  /// `Expert`, or `Custom 40 mines on 16 x 16`. The same wording is used for
  /// every custom game, so local and online scores read alike.
  String get board =>
      category == ScoreCategory.beginner ||
          category == ScoreCategory.intermediate ||
          category == ScoreCategory.expert
      ? category.label
      : "Custom $mines mines on $width x $height";

  GameDifficulty get difficulty =>
      GameDifficulty.custom(width: width, height: height, mines: mines);

  /// What goes in the score's `additionalData` (the board itself is added to
  /// it when the game is won, so the admin can draw it).
  String toAdditionalData() => jsonEncode({
    "game": "anothermine",
    "version": 1,
    "difficulty": category.label.toLowerCase(),
    "width": width,
    "height": height,
    "mines": mines,
    "solver": solver.name,
  });

  static Map<String, dynamic> parseAdditionalData(String? data) {
    if (data == null || data.isEmpty) return const {};

    try {
      final dynamic decoded = jsonDecode(data);

      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}
