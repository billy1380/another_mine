import "dart:math";

import "package:another_mine_common/ai/interaction_type.dart";
import "package:another_mine_common/ai/probability_guesser.dart";
import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_common/logic/pattern_game_builder.dart";
import "package:another_mine_common/model/colour.dart";
import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/model/game_state_type.dart";
import "package:another_mine_common/model/tile_state_type.dart";
import "package:test/test.dart";
import "package:willshex/willshex.dart";

import "../fixtures.dart";

const _seed = 1;
void main() {
  late GameState gameState;
  late ProbabilityGuesser guesser;

  setUpAll(() {
    setupLogging();
  });

  setUp(() {
    gameState = GameState.initial(
      GameDifficulty.beginner,
      const Colour(0xFF000000),
    );
    gameState = gameState.copyWith(
      status: GameStateType.started,
      start: DateTime.now(),
    );

    guesser = ProbabilityGuesser(Random(_seed));
  });

  group("ProbabilityGuesser", () {
    test("probes tiles with 0% probability", () {
      final pattern = safePair;
      final builder = PatternGameBuilder(pattern);
      final difficulty = GameDifficulty.custom(width: 2, height: 1, mines: 0);

      gameState = GameState.initial(
        difficulty,
        const Colour(0xFF000000),
        builder,
      );
      gameState = gameState.copyWith(
        status: GameStateType.started,
        start: DateTime.now(),
      );

      gameState.tiles[0].state = TileStateType.revealedSafe;

      final move = guesser.makeAMove(
        gameState.tiles,
        gameState.difficulty,
        gameState.status,
      );

      expect(move.type, InteractionType.probe);
      expect(move.x, 1);
      expect(move.y, 0);
    });

    test("speculates (flags) tiles with 100% probability", () {
      final pattern = safeAndMine;
      final builder = PatternGameBuilder(pattern);
      final difficulty = GameDifficulty.custom(width: 2, height: 1, mines: 1);

      gameState = GameState.initial(
        difficulty,
        const Colour(0xFF000000),
        builder,
      );
      gameState = gameState.copyWith(
        status: GameStateType.started,
        start: DateTime.now(),
      );

      gameState.tiles[0].state = TileStateType.one;

      final move = guesser.makeAMove(
        gameState.tiles,
        gameState.difficulty,
        gameState.status,
      );

      expect(move.type, InteractionType.speculate);
      expect(move.x, 1);
      expect(move.y, 0);
    });

    test("prioritizes flagging mines over revealing safe tiles", () {
      final customPattern = [
        [false, true, false, false],
      ];
      final builder = PatternGameBuilder(customPattern);
      final difficulty = GameDifficulty.custom(width: 4, height: 1, mines: 1);

      gameState = GameState.initial(
        difficulty,
        const Colour(0xFF000000),
        builder,
      );
      gameState = gameState.copyWith(
        status: GameStateType.started,
        start: DateTime.now(),
      );

      gameState.tiles[0].state = TileStateType.one;
      gameState.tiles[2].state = TileStateType.one;

      final move = guesser.makeAMove(
        gameState.tiles,
        gameState.difficulty,
        gameState.status,
      );

      expect(move.type, InteractionType.speculate);
      expect(move.x, 1);
      expect(move.y, 0);
    });

    test("picks tile with lowest probability when no certain move", () {
      final pattern = [
        [true, false, false],
      ];
      final builder = PatternGameBuilder(pattern);
      final difficulty = GameDifficulty.custom(width: 3, height: 1, mines: 1);

      gameState = GameState.initial(
        difficulty,
        const Colour(0xFF000000),
        builder,
      );
      gameState = gameState.copyWith(
        status: GameStateType.started,
        start: DateTime.now(),
      );

      gameState.tiles[1].state = TileStateType.one;

      final move = guesser.makeAMove(
        gameState.tiles,
        gameState.difficulty,
        gameState.status,
      );

      expect(move.type, InteractionType.probe);
      expect(move.x == 0 || move.x == 2, isTrue);
      expect(move.y, 0);
    });

    test("does nothing if game is finished", () {
      final pattern = safePair;
      final builder = PatternGameBuilder(pattern);
      final difficulty = GameDifficulty.custom(width: 2, height: 1, mines: 0);

      gameState = GameState.initial(
        difficulty,
        const Colour(0xFF000000),
        builder,
      );
      gameState = gameState.copyWith(
        status: GameStateType.won,
        start: DateTime.now(),
      );

      final move = guesser.makeAMove(
        gameState.tiles,
        gameState.difficulty,
        gameState.status,
      );

      expect(move.type, InteractionType.none);
    });
  });
}
