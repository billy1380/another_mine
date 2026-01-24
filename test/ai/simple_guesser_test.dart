import "dart:math";

import "package:another_mine/ai/game_move.dart";
import "package:another_mine/ai/simple_guesser.dart";
import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/model/tile_model.dart";
import "package:another_mine/model/tile_state_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

import "../mocks.dart";

const _seed = 1;

void main() {
  late MockGameBloc mockGameBloc;
  late GameState gameState;
  late SimpleGuesser guesser;

  setUpAll(() {
    registerFallbackValue(FakeProbe());
    registerFallbackValue(FakeSpeculate());
  });

  setUp(() {
    mockGameBloc = MockGameBloc();
    gameState = GameState.initial(GameDifficulty.beginner, Colors.black);
    gameState = gameState.copyWith(status: GameStateType.started);

    guesser = SimpleGuesser(Random(_seed));

    when(() => mockGameBloc.state).thenAnswer((_) => gameState);
  });

  TileModel createTile({
    required int index,
    TileStateType state = TileStateType.notPressed,
    bool hasMine = false,
  }) {
    return TileModel()
      ..index = index
      ..state = state
      ..hasMine = hasMine
      ..clearNeighbours();
  }

  group("SimpleGuesser", () {
    test("flags all neighbours if tile value equals unrevealed neighbours", () {
      final center = createTile(index: 0, state: TileStateType.one);
      final neighbour = createTile(index: 1, state: TileStateType.notPressed);

      center.neighbours[4] = neighbour; // Right

      // We replace the tiles in the state
      gameState = gameState.copyWith(tiles: [center, neighbour]);

      final move = guesser.makeAMove(
        gameState.tiles,
        gameState.difficulty,
        gameState.status,
      );

      expect(move.type, InteractionType.speculate);
      expect(move.x, 1);
      expect(move.y, 0);
    });

    test("clicks remaining neighbours if flags equal tile value", () {
      final center = createTile(index: 0, state: TileStateType.one);
      final flagged =
          createTile(index: 1, state: TileStateType.predictedBombCorrect);
      final unrevealed = createTile(index: 2, state: TileStateType.notPressed);

      center.neighbours[0] = flagged;
      center.neighbours[1] = unrevealed;

      gameState = gameState.copyWith(tiles: [center, flagged, unrevealed]);

      final move = guesser.makeAMove(
        gameState.tiles,
        gameState.difficulty,
        gameState.status,
      );

      expect(move.type, InteractionType.probe);
      expect(move.x, 0);
      expect(move.y, 0);
    });

    test("makes random move if no logical move is found", () {
      final tile = createTile(index: 0, state: TileStateType.notPressed);

      gameState = gameState.copyWith(tiles: [tile]);

      final move = guesser.makeAMove(
        gameState.tiles,
        gameState.difficulty,
        gameState.status,
      );

      expect(move.type, InteractionType.probe);
      expect(move.x, 0);
      expect(move.y, 0);
    });

    test("does nothing if game is finished", () {
      gameState = gameState.copyWith(status: GameStateType.won);

      final tile = createTile(index: 0, state: TileStateType.notPressed);
      gameState = gameState.copyWith(tiles: [tile]);

      final move = guesser.makeAMove(
        gameState.tiles,
        gameState.difficulty,
        gameState.status,
      );

      expect(move.type, InteractionType.none);
    });
  });
}
