import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/pages/game_page.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:mocktail/mocktail.dart";

class MockGameBloc extends Mock implements GameBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGameBloc mockBloc;
  late GameState gameState;

  setUp(() {
    mockBloc = MockGameBloc();
    gameState = GameState.initial(GameDifficulty.beginner, Colors.black);
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(gameState));
    when(() => mockBloc.state).thenReturn(gameState);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<GameBloc>.value(
        value: mockBloc,
        child: const GamePage(),
      ),
    );
  }

  testWidgets("AutoSolver button is enabled when game is running",
      (tester) async {
    when(() => mockBloc.state)
        .thenReturn(gameState.copyWith(status: GameStateType.started));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Find the IconButton containing the specific icon
    final buttonFinder =
        find.widgetWithIcon(IconButton, Icons.smart_toy_outlined);
    expect(buttonFinder, findsOneWidget);

    final IconButton button = tester.widget(buttonFinder);
    expect(button.onPressed, isNotNull, reason: "Button should be enabled");
  });

  testWidgets("AutoSolver button is DISABLED when game is WON", (tester) async {
    final wonState = gameState.copyWith(status: GameStateType.won);
    when(() => mockBloc.state).thenReturn(wonState);
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(wonState));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final buttonFinder =
        find.widgetWithIcon(IconButton, Icons.smart_toy_outlined);
    expect(buttonFinder, findsOneWidget);

    final IconButton button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull, reason: "Button should be disabled");
  });

  testWidgets("AutoSolver button is DISABLED when game is LOST",
      (tester) async {
    final lostState = gameState.copyWith(status: GameStateType.lost);
    when(() => mockBloc.state).thenReturn(lostState);
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(lostState));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final buttonFinder =
        find.widgetWithIcon(IconButton, Icons.smart_toy_outlined);
    expect(buttonFinder, findsOneWidget);

    final IconButton button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull, reason: "Button should be disabled");
  });
}
