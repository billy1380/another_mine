import "dart:async";

import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/bloc/startup/startup_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/pages/startup_page.dart";
import "package:another_mine/services/pref.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

import "../mocks.dart";

class MockStartupBloc extends Mock implements StartupBloc {}

void main() {
  late MockGameBloc mockGameBloc;
  late MockStartupBloc mockStartupBloc;
  late FakePref pref;
  late GoRouter router;

  setUpAll(() {
    registerFallbackValue(GameDifficulty.beginner);
    registerFallbackValue(const NewGame(difficulty: GameDifficulty.beginner));
    registerFallbackValue(const InitializeApp());
    registerFallbackValue(const StartupState());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockGameBloc = MockGameBloc();
    final initialGameState =
        GameState.initial(GameDifficulty.none, Colors.black);
    when(() => mockGameBloc.stream)
        .thenAnswer((_) => Stream.value(initialGameState));
    when(() => mockGameBloc.state).thenReturn(initialGameState);

    mockStartupBloc = MockStartupBloc();
    when(() => mockStartupBloc.stream)
        .thenAnswer((_) => Stream.value(const StartupState()));
    when(() => mockStartupBloc.state).thenReturn(const StartupState());

    pref = FakePref();
    when(() => pref.init()).thenAnswer((_) async => true);
    when(() => pref.difficulty).thenReturn(GameDifficulty.beginner);

    ServiceDiscovery.instance.register<Pref>(pref);
    await ServiceDiscovery.instance.init();
  });

  Widget createWidget(StartupState startupState) {
    when(() => mockStartupBloc.state).thenReturn(startupState);
    when(() => mockStartupBloc.stream)
        .thenAnswer((_) => Stream.value(startupState));

    router = GoRouter(
      initialLocation: StartupPage.routerPath,
      routes: [
        GoRoute(
          path: StartupPage.routerPath,
          builder: StartupPage.builder,
        ),
        GoRoute(
          path: "/game/:width/:height/:mines",
          builder: (context, state) => const Scaffold(body: Text("Game Page")),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<GameBloc>.value(value: mockGameBloc),
        BlocProvider<StartupBloc>.value(value: mockStartupBloc),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets(
      "StartupPage dispatches InitializeApp on init", (tester) async {
    await tester.pumpWidget(createWidget(const StartupState()));
    
    verify(() => mockStartupBloc.add(const InitializeApp())).called(1);
  });

  testWidgets(
      "StartupPage navigates to GamePage when StartupStatus is complete (beginner)",
      (tester) async {
    // Arrange
    when(() => pref.difficulty).thenReturn(GameDifficulty.beginner);
    
    // Create a controller to emit states
    final startupController = StreamController<StartupState>.broadcast();
    addTearDown(startupController.close);
    
    when(() => mockStartupBloc.stream).thenAnswer((_) => startupController.stream);
    when(() => mockStartupBloc.state).thenReturn(const StartupState());

    router = GoRouter(
      initialLocation: StartupPage.routerPath,
      routes: [
        GoRoute(
          path: StartupPage.routerPath,
          builder: StartupPage.builder,
        ),
        GoRoute(
          path: "/game/:width/:height/:mines",
          builder: (context, state) => const Scaffold(body: Text("Game Page")),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<GameBloc>.value(value: mockGameBloc),
          BlocProvider<StartupBloc>.value(value: mockStartupBloc),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    
    // Emit complete state
    final completeState = const StartupState(status: StartupStatus.complete);
    when(() => mockStartupBloc.state).thenReturn(completeState);
    startupController.add(completeState);

    // Re-pump to trigger listener and navigation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100)); 

    expect(find.text("Game Page"), findsOneWidget);
  });
}