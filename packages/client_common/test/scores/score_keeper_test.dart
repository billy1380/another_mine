import "dart:io";

import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_common/model/colour.dart";
import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/model/game_state_type.dart";
import "package:another_mine_common/scores/local_score.dart";
import "package:another_mine_common/scores/score_category.dart";
import "package:another_mine_common/scores/score_keeper.dart";
import "package:another_mine_common/services/pref.dart";
import "package:another_mine_common/services/pref_storage.dart";
import "package:test/test.dart";

GameState won(
  GameDifficulty difficulty, {
  int seconds = 40,
  bool solverUsed = false,
}) => GameState.initial(difficulty, const Colour(0xFF000000)).copyWith(
  status: GameStateType.won,
  accumulatedDuration: Duration(seconds: seconds),
  solverUsed: solverUsed,
);

void main() {
  late Directory dir;
  late Pref pref;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync("score_keeper_");
    pref = Pref("test_", InMemoryPrefStorage());
    await pref.init();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<ScoreKeeper> openKeeper([String? path]) async {
    final keeper = ScoreKeeper(path ?? "${dir.path}/scores", pref);
    await keeper.init();

    return keeper;
  }

  group("WonGame", () {
    test("is only made from a won game", () {
      final lost = GameState.initial(
        GameDifficulty.beginner,
        const Colour(0xFF000000),
      ).copyWith(status: GameStateType.lost);

      expect(WonGame.from(lost, pref), isNull);
      expect(WonGame.from(won(GameDifficulty.beginner), pref), isNotNull);
    });

    test("takes the time, board and category from the game", () {
      final game = WonGame.from(
        won(GameDifficulty.expert, seconds: 123),
        pref,
      )!;

      expect(game.seconds, 123);
      expect(game.width, 30);
      expect(game.mines, 99);
      expect(game.category, ScoreCategory.expert);
      expect(game.solver, Solver.human);
    });

    test("a game the solver played is credited to the solver", () {
      final game = WonGame.from(
        won(GameDifficulty.beginner, solverUsed: true),
        pref,
      )!;

      expect(game.solver, Solver.simple);
    });
  });

  group("ScoreKeeper", () {
    test("keeps nothing without a path", () async {
      final keeper = ScoreKeeper(null, pref);
      await keeper.init();

      expect(keeper.isEnabled, isFalse);
      expect(keeper.wonGame(won(GameDifficulty.beginner)), isNull);
      expect(await keeper.top(ScoreCategory.beginner), isEmpty);
    });

    test("a game the solver played is not kept", () async {
      final keeper = await openKeeper();

      expect(
        keeper.wonGame(won(GameDifficulty.beginner, solverUsed: true)),
        isNull,
      );
    });

    test("says where a win places, then keeps it with a name", () async {
      final keeper = await openKeeper();
      final game = keeper.wonGame(won(GameDifficulty.beginner, seconds: 50))!;

      expect(await keeper.rankOf(game), 1);
      expect(await keeper.keep(game, "  billy  "), 1);

      final better = keeper.wonGame(won(GameDifficulty.beginner, seconds: 30))!;
      expect(await keeper.rankOf(better), 1);
      expect(await keeper.rankOf(game), 2);

      final top = await keeper.top(ScoreCategory.beginner);
      expect(top.single.name, "billy");
      expect(top.single.seconds, 50);
    });

    test("remembers the name for the next win", () async {
      final keeper = await openKeeper();

      await keeper.keep(keeper.wonGame(won(GameDifficulty.beginner))!, "billy");

      expect(pref.playerName, "billy");
    });

    test("removes one score and clears a category", () async {
      final keeper = await openKeeper();

      for (final seconds in [10, 20, 30]) {
        await keeper.keep(
          keeper.wonGame(won(GameDifficulty.beginner, seconds: seconds))!,
          "billy",
        );
      }

      final top = await keeper.top(ScoreCategory.beginner);
      await keeper.remove(top.first);
      expect((await keeper.top(ScoreCategory.beginner)).map((s) => s.seconds), [
        20,
        30,
      ]);

      await keeper.clearCategory(ScoreCategory.beginner);
      expect(await keeper.top(ScoreCategory.beginner), isEmpty);
    });
  });
}
