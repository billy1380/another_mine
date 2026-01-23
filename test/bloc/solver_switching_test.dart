import "package:another_mine/ai/probability_guesser.dart";
import "package:another_mine/ai/simple_guesser.dart";
import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/services/pref.dart";
import "package:flutter_test/flutter_test.dart";
import "package:main_thread_processor/main_thread_processor.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("GameBloc Solver Switching", () {
    late GameBloc gameBloc;
    late Processor processor;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        "test_autoSolver": true,
      });
      await Pref.service.init("test_");
      processor = Processor();
      Scheduler.shared.period = 0;
      gameBloc = GameBloc(
        processor: processor,
      );
    });

    tearDown(() {
      processor.removeAllTasks();
      gameBloc.close();
    });

    test("defaults to SimpleGuesser", () {
      expect(gameBloc.guesser, isA<SimpleGuesser>());
      expect(gameBloc.guesser, isNot(isA<ProbabilityGuesser>()));
    });

    test("switches to ProbabilityGuesser when pref changes", () async {
      // Start game
      gameBloc.add(const NewGame(difficulty: GameDifficulty.beginner));
      await Future.delayed(const Duration(milliseconds: 10));

      // Enable Auto Solver
      gameBloc.add(const ToggleAutoSolver());
      await Future.delayed(const Duration(milliseconds: 10));

      // Initially Simple
      expect(gameBloc.guesser, isA<SimpleGuesser>());
      expect(gameBloc.guesser, isNot(isA<ProbabilityGuesser>()));

      // Change Pref
      await Pref.service.setString(Pref.keyAutoSolverType, "probability");

      // Trigger next move logic
      gameBloc.add(const AutoSolverNextMove());
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify switch
      expect(gameBloc.guesser, isA<ProbabilityGuesser>());
    });

    test("switches back to SimpleGuesser", () async {
      // Set to Probability first
      await Pref.service.setString(Pref.keyAutoSolverType, "probability");

      gameBloc.add(const NewGame(difficulty: GameDifficulty.beginner));
      await Future.delayed(const Duration(milliseconds: 10));

      // Enable Auto Solver
      gameBloc.add(const ToggleAutoSolver());
      await Future.delayed(const Duration(milliseconds: 10));

      // Trigger move (auto triggered by toggle, but let's be sure or wait)

      expect(gameBloc.guesser, isA<ProbabilityGuesser>());

      // Set to Simple
      await Pref.service.setString(Pref.keyAutoSolverType, "simple");

      // Reset game to ensure valid state
      gameBloc.add(const NewGame(difficulty: GameDifficulty.beginner));
      await Future.delayed(const Duration(milliseconds: 10));

      // Ensure enabled
      if (!gameBloc.state.autoSolverEnabled) {
        gameBloc.add(const ToggleAutoSolver());
        await Future.delayed(const Duration(milliseconds: 10));
      } else {
        gameBloc.add(const AutoSolverNextMove());
        await Future.delayed(const Duration(milliseconds: 10));
      }

      expect(gameBloc.guesser, isA<SimpleGuesser>());
      expect(gameBloc.guesser, isNot(isA<ProbabilityGuesser>()));
    });
  });
}
