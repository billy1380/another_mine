import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/tile_model.dart";
import "package:another_mine/model/tile_state_type.dart";
import "package:another_mine/widgets/tile.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class MockGameBloc extends Mock implements GameBloc {}

void main() {
  late MockGameBloc mockBloc;
  late GameState gameState;

  setUpAll(() {
    final dummyModel = TileModel()..index = -1; // Dummy model
    registerFallbackValue(Speculate(model: dummyModel));
    registerFallbackValue(MightPlay(model: dummyModel));
    registerFallbackValue(Probe(model: dummyModel));
    registerFallbackValue(const DonePlaying());
  });

  setUp(() {
    mockBloc = MockGameBloc();
    gameState = GameState.initial(GameDifficulty.beginner, Colors.black);

    // Default mocks
    when(() => mockBloc.state).thenReturn(gameState);
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(gameState));
  });

  // Helper to create a TileModel since the constructor is empty and fields are late
  TileModel createTileModel({
    required int index,
    TileStateType state = TileStateType.notPressed,
    bool hasMine = false,
  }) {
    final model = TileModel();
    model.index = index;
    model.state = state;
    model.hasMine = hasMine;
    model.colour = Colors.white;
    model.neighbours = List.filled(8, null);
    model.neigbouringMine = 0;
    return model;
  }

  group("Tile Gesture Tests", () {
    testWidgets("Valid secondary tap triggers Speculate", (tester) async {
      final tileModel = createTileModel(index: 0);

      when(() => mockBloc.state).thenReturn(gameState);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GameBloc>.value(
            value: mockBloc,
            child: Tile(const Key("tile_0"), tileModel),
          ),
        ),
      );

      // Perform a secondary tap (Right click)
      // This sends Down then Up.
      await tester.tap(find.byType(Tile), buttons: kSecondaryButton);
      await tester.pump();

      // Verify Speculate was added
      verify(() => mockBloc.add(any(that: isA<Speculate>()))).called(1);
    });

    testWidgets("Cancelled secondary tap (Drag) does NOT trigger Speculate",
        (tester) async {
      final tileModel = createTileModel(index: 0);

      when(() => mockBloc.state).thenReturn(gameState);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GameBloc>.value(
            value: mockBloc,
            child: Tile(const Key("tile_0"), tileModel),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Tile)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await tester.pump();

      // Down should NOT trigger.
      verifyNever(() => mockBloc.add(any(that: isA<Speculate>())));

      // Move properly to trigger drag/cancel if possible in this environment,
      // or just manually cancel.
      await gesture.moveTo(const Offset(500, 500));
      await gesture.cancel();

      // Verify no Speculate event.
      verifyNever(() => mockBloc.add(any(that: isA<Speculate>())));
    });

    testWidgets("Secondary Down then Up triggers Speculate", (tester) async {
      final tileModel = createTileModel(index: 0);

      when(() => mockBloc.state).thenReturn(gameState);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GameBloc>.value(
            value: mockBloc,
            child: Tile(const Key("tile_0"), tileModel),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Tile)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await tester.pump();

      // Down should NOT trigger yet
      verifyNever(() => mockBloc.add(any(that: isA<Speculate>())));

      await gesture.up();
      await tester.pump();

      // Up should trigger
      verify(() => mockBloc.add(any(that: isA<Speculate>()))).called(1);
    });
  });
}
