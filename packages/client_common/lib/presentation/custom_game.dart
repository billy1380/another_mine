import "package:another_mine_common/model/game_difficulty.dart";
import "package:collection/collection.dart";
import "package:willshex/willshex.dart";

/// Limits and helpers for the custom game form, shared by the clients.
abstract class CustomGame {
  CustomGame._();

  static const int minWidth = 5;
  static const int maxWidth = 50;
  static const int minHeight = 5;
  static const int maxHeight = 50;
  static const int minMines = 1;

  /// The most mines a board can hold and still leave room for a first click.
  static int maxMinesFor(int width, int height) =>
      ((width * height) - 9).clamp(minMines, 1 << 20);

  /// [mines] kept within what a [width] by [height] board can hold.
  static int clampMines(int mines, int width, int height) =>
      mines.clamp(minMines, maxMinesFor(width, height));

  /// The name of the difficulty a board matches, or "Custom".
  static String nameFor(int width, int height, int mines) {
    final GameDifficulty? difficulty = GameDifficulty.values.firstWhereOrNull(
      (e) => e.sameAs(width, height, mines),
    );

    return StringUtils.upperCaseFirstLetter(difficulty?.name) ?? "Custom";
  }
}

/// How hard a mine density is, as traffic lights.
enum Rag { green, amber, red }

/// Whether a board with [mines] on [width] by [height] is easy, middling or
/// hard, judged against the standard difficulties.
Rag ragFor(int width, int height, int mines) {
  final double current = mines / (width * height);
  final double beginner =
      GameDifficulty.beginner.mines / GameDifficulty.beginner.area;
  final double intermediate =
      GameDifficulty.intermediate.mines / GameDifficulty.intermediate.area;
  final double expert =
      GameDifficulty.expert.mines / GameDifficulty.expert.area;

  final double beginnerToIntermediate =
      beginner + ((intermediate - beginner) * 0.5);
  final double intermediateToExpert =
      intermediate + ((expert - intermediate) * 0.5);

  if (current < beginnerToIntermediate) return Rag.green;
  if (current < intermediateToExpert) return Rag.amber;
  return Rag.red;
}
