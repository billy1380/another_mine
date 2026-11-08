import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/scores/score_category.dart";
import "package:test/test.dart";

void main() {
  group("ScoreCategory", () {
    test("the presets keep their own category", () {
      expect(
        ScoreCategory.forDifficulty(GameDifficulty.beginner),
        ScoreCategory.beginner,
      );
      expect(
        ScoreCategory.forDifficulty(GameDifficulty.intermediate),
        ScoreCategory.intermediate,
      );
      expect(
        ScoreCategory.forDifficulty(GameDifficulty.expert),
        ScoreCategory.expert,
      );
    });

    test("a custom board that is exactly a preset is that preset", () {
      expect(
        ScoreCategory.forDifficulty(
          GameDifficulty.custom(width: 9, height: 9, mines: 10),
        ),
        ScoreCategory.beginner,
      );
    });

    test("a custom board is ranked by mine density", () {
      GameDifficulty custom(int w, int h, int m) =>
          GameDifficulty.custom(width: w, height: h, mines: m);

      // beginner is 10 / 81, about 0.123; intermediate is 40 / 256, 0.156
      expect(ScoreCategory.forDifficulty(custom(5, 5, 1)), ScoreCategory.easy);
      expect(
        ScoreCategory.forDifficulty(custom(20, 20, 40)),
        ScoreCategory.easy,
      ); // 0.10
      expect(
        ScoreCategory.forDifficulty(custom(10, 10, 14)),
        ScoreCategory.medium,
      ); // 0.14
      expect(
        ScoreCategory.forDifficulty(custom(10, 10, 20)),
        ScoreCategory.hard,
      ); // 0.20
      expect(
        ScoreCategory.forDifficulty(custom(10, 10, 40)),
        ScoreCategory.hard,
      ); // denser than expert is still hard
    });

    test("a density equal to a preset but on another board is not easier", () {
      // 10 / 81 exactly, on a board that is not the Beginner board
      final board = GameDifficulty.custom(width: 18, height: 9, mines: 20);

      expect(
        board.difficultyFactor,
        greaterThanOrEqualTo(GameDifficulty.beginner.difficultyFactor),
      );
      expect(ScoreCategory.forDifficulty(board), isNot(ScoreCategory.easy));
    });

    test("local ids map back to categories", () {
      for (final category in ScoreCategory.values) {
        expect(ScoreCategory.forLocalId(category.localId), category);
      }
      expect(ScoreCategory.forLocalId(99), isNull);
    });
  });
}
