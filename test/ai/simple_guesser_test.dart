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
    // Ensure state is "started" or similar so isNotFinished is true
    gameState = gameState.copyWith(status: GameStateType.started);

    guesser = SimpleGuesser(mockGameBloc);

    // We need to return the *current* state when accessed.
    // By using a closure, we return the current value of the variable `gameState`
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

      guesser.makeAMove();

      verify(() => mockGameBloc.add(any(
          that: isA<Speculate>()
              .having((e) => e.model, "model", neighbour)))).called(1);
    });

    test("clicks remaining neighbours if flags equal tile value", () {
      final center = createTile(index: 0, state: TileStateType.one);
      final flagged =
          createTile(index: 1, state: TileStateType.predictedBombCorrect);
      final unrevealed = createTile(index: 2, state: TileStateType.notPressed);

      center.neighbours[0] = flagged;
      center.neighbours[1] = unrevealed;

      gameState = gameState.copyWith(tiles: [center, flagged, unrevealed]);

      guesser.makeAMove();

      verify(() => mockGameBloc.add(
              any(that: isA<Probe>().having((e) => e.model, "model", center))))
          .called(1);
    });

    test("makes random move if no logical move is found", () {
      final tile = createTile(index: 0, state: TileStateType.notPressed);

      gameState = gameState.copyWith(tiles: [tile]);

      guesser.makeAMove();

      verify(() => mockGameBloc.add(
              any(that: isA<Probe>().having((e) => e.model, "model", tile))))
          .called(1);
    });

    test("does nothing if game is finished", () {
      gameState = gameState.copyWith(status: GameStateType.won);

      final tile = createTile(index: 0, state: TileStateType.notPressed);
      gameState = gameState.copyWith(tiles: [tile]);

      guesser.makeAMove();

      verifyNever(() => mockGameBloc.add(any()));
    });
  });
}
