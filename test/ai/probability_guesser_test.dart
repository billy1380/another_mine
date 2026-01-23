import "dart:math";

import "package:another_mine/ai/probability_guesser.dart";
import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/logic/pattern_game_builder.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/model/tile_state_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:willshex/willshex.dart";

import "../fixtures.dart";
import "../mocks.dart";

const _seed = 1;
void main() {
  late MockGameBloc mockGameBloc;
  late GameState gameState;
  late ProbabilityGuesser guesser;

  setUpAll(() {
    setupLogging();
    registerFallbackValue(FakeProbe());
    registerFallbackValue(FakeSpeculate());
  });

  setUp(() {
    mockGameBloc = MockGameBloc();
    gameState = GameState.initial(GameDifficulty.beginner, Colors.black);
    gameState = gameState.copyWith(
      status: GameStateType.started,
      start: DateTime.now(),
    );

    guesser = ProbabilityGuesser(Random(_seed), mockGameBloc);

    when(() => mockGameBloc.state).thenAnswer((_) => gameState);
  });

  group("ProbabilityGuesser", () {
    test("probes tiles with 0% probability", () {
      final pattern = safePair;
      final builder = PatternGameBuilder(pattern);
      final difficulty = GameDifficulty.custom(
        width: 2,
        height: 1,
        mines: 0,
      );

      gameState = GameState.initial(difficulty, Colors.black, builder);
      gameState = gameState.copyWith(
          status: GameStateType.started, start: DateTime.now());

      gameState.tiles[0].state = TileStateType.revealedSafe;

      guesser.makeAMove();

      verify(() => mockGameBloc.add(
              any(that: isA<Probe>().having((e) => e.model.index, "index", 1))))
          .called(1);
    });

    test("speculates (flags) tiles with 100% probability", () {
      final pattern = safeAndMine;
      final builder = PatternGameBuilder(pattern);
      final difficulty = GameDifficulty.custom(
        width: 2,
        height: 1,
        mines: 1,
      );

      gameState = GameState.initial(difficulty, Colors.black, builder);
      gameState = gameState.copyWith(
          status: GameStateType.started, start: DateTime.now());

      gameState.tiles[0].state = TileStateType.one;

      guesser.makeAMove();

      verify(() => mockGameBloc.add(any(
              that: isA<Speculate>().having((e) => e.model.index, "index", 1))))
          .called(1);
    });

    test("prioritizes flagging mines over revealing safe tiles", () {
      final customPattern = [
        [false, true, false, false]
      ];
      final builder = PatternGameBuilder(customPattern);
      final difficulty = GameDifficulty.custom(
        width: 4,
        height: 1,
        mines: 1,
      );

      gameState = GameState.initial(difficulty, Colors.black, builder);
      gameState = gameState.copyWith(
          status: GameStateType.started, start: DateTime.now());

      gameState.tiles[0].state = TileStateType.one;
      gameState.tiles[2].state = TileStateType.one;

      guesser.makeAMove();

      verify(() => mockGameBloc.add(any(
              that: isA<Speculate>().having((e) => e.model.index, "index", 1))))
          .called(1);
      verifyNever(() => mockGameBloc.add(any(that: isA<Probe>())));
    });

    test("picks tile with lowest probability when no certain move", () {
      final pattern = [
        [true, false, false]
      ];
      final builder = PatternGameBuilder(pattern);
      final difficulty = GameDifficulty.custom(
        width: 3,
        height: 1,
        mines: 1,
      );

      gameState = GameState.initial(difficulty, Colors.black, builder);
      gameState = gameState.copyWith(
          status: GameStateType.started, start: DateTime.now());

      gameState.tiles[1].state = TileStateType.one;

      guesser.makeAMove();

      verify(() => mockGameBloc.add(any(that: isA<Probe>()))).called(1);
    });

    test("does nothing if game is finished", () {
      final pattern = safePair;
      final builder = PatternGameBuilder(pattern);
      final difficulty = GameDifficulty.custom(width: 2, height: 1, mines: 0);

      gameState = GameState.initial(difficulty, Colors.black, builder);
      gameState =
          gameState.copyWith(status: GameStateType.won, start: DateTime.now());

      guesser.makeAMove();

      verifyNever(() => mockGameBloc.add(any()));
    });
  });
}
