import "package:another_mine/ai/probability_guesser.dart";
import "package:another_mine/ai/simple_guesser.dart";
import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/services/pref.dart";
import "package:another_mine/services/provider.dart";
import "package:flutter_test/flutter_test.dart";
import "package:main_thread_processor/main_thread_processor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:willshex/willshex.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    setupLogging();
  });

  group("GameBloc Solver Switching", () {
    late GameBloc gameBloc;
    late Processor processor;
    // Very large board to prevent finishing
    final GameDifficulty testDifficulty =
        GameDifficulty.custom(width: 100, height: 100, mines: 500);

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        "test_autoSolver": true,
      });
      ServiceDiscovery.instance.register(Pref("test_"));
      await ServiceDiscovery.instance.init();

      processor = Processor();
      Scheduler.shared.period = 0;
      gameBloc = GameBloc(
        processor: processor,
      );
    });

    tearDown(() async {
      if (gameBloc.state.autoSolverEnabled) {
        gameBloc.add(const ToggleAutoSolver());
        await gameBloc.stream.firstWhere((s) => !s.autoSolverEnabled).timeout(
            const Duration(milliseconds: 200),
            onTimeout: () => gameBloc.state);
      }
      processor.removeAllTasks();
      await gameBloc.close();
    });

    test("defaults to SimpleGuesser", () {
      expect(gameBloc.guesser, isA<SimpleGuesser>());
      expect(gameBloc.guesser, isNot(isA<ProbabilityGuesser>()));
    });

    test("switches to ProbabilityGuesser when pref changes", () async {
      // 1. Start game
      gameBloc.add(NewGame(difficulty: testDifficulty));
      await Future.delayed(const Duration(milliseconds: 100));

      // 2. Enable Auto Solver
      gameBloc.add(const ToggleAutoSolver());
      await Future.delayed(const Duration(milliseconds: 100));

      // Initially Simple
      expect(gameBloc.guesser, isA<SimpleGuesser>());

      // 3. Change Pref
      await Provider.pref.setString(Pref.keyAutoSolverType, "probability");

      // 4. Trigger next move logic
      gameBloc.add(const AutoSolverNextMove());
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify switch
      expect(gameBloc.guesser, isA<ProbabilityGuesser>());
    });

    test("switches back to SimpleGuesser", () async {
      // 1. Set to Probability first
      await Provider.pref.setString(Pref.keyAutoSolverType, "probability");

      gameBloc.add(NewGame(difficulty: testDifficulty));
      await Future.delayed(const Duration(milliseconds: 100));

      // 2. Enable Auto Solver
      gameBloc.add(const ToggleAutoSolver());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(gameBloc.guesser, isA<ProbabilityGuesser>());

      // 3. Set to Simple
      await Provider.pref.setString(Pref.keyAutoSolverType, "simple");

      // 4. Reset game and trigger
      gameBloc.add(NewGame(difficulty: testDifficulty));
      await Future.delayed(const Duration(milliseconds: 100));

      if (!gameBloc.state.autoSolverEnabled) {
        gameBloc.add(const ToggleAutoSolver());
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        gameBloc.add(const AutoSolverNextMove());
        await Future.delayed(const Duration(milliseconds: 100));
      }

      expect(gameBloc.guesser, isA<SimpleGuesser>());
      expect(gameBloc.guesser, isNot(isA<ProbabilityGuesser>()));
    });

    test("swapping solver does not reset game state", () async {
      // 1. Start a new game
      gameBloc.add(NewGame(difficulty: testDifficulty));
      await Future.delayed(const Duration(milliseconds: 100));

      // 2. Initial probe to move out of 'notStarted'
      gameBloc.add(Probe(model: gameBloc.state.tiles[0]));
      await Future.delayed(const Duration(milliseconds: 100));

      final initialState = gameBloc.state;
      final initialStartTime = initialState.start;
      final initialRevealedCount = initialState.revealedTiles;

      // 3. Change strategy and trigger move
      await Provider.pref.setString(Pref.keyAutoSolverType, "probability");

      if (!gameBloc.state.autoSolverEnabled) {
        gameBloc.add(const ToggleAutoSolver());
      } else {
        gameBloc.add(const AutoSolverNextMove());
      }
      await Future.delayed(const Duration(milliseconds: 100));

      // 4. Verify strategy changed but state is preserved
      expect(gameBloc.guesser, isA<ProbabilityGuesser>());

      final currentState = gameBloc.state;
      expect(currentState.start, equals(initialStartTime),
          reason: "Start time should be preserved");
      expect(currentState.revealedTiles,
          greaterThanOrEqualTo(initialRevealedCount),
          reason: "Revealed tiles should not decrease");
    });
  });
}
