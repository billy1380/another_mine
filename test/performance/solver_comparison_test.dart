@Tags(["comparison"])
@Timeout(Duration(minutes: 15))
library;

import "dart:async";

import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/services/pref.dart";
import "package:flutter_test/flutter_test.dart";
import "package:logging/logging.dart";
import "package:main_thread_processor/main_thread_processor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:willshex/willshex.dart";

void main() {
  final Logger log = Logger("SolverComparison");

  setUpAll(() async {
    setupLogging();

    SharedPreferences.setMockInitialValues({
      "test_autoSolver": true,
    });
    await Pref.service.init("test_");
  });

  Future<GameResult> runGame(bool useProbability, Processor processor,
      GameDifficulty difficulty) async {
    final bloc = GameBloc(
      processor: processor,
      lostGamePause: 0,
    );
    await Pref.service.setString(
        Pref.keyAutoSolverType, useProbability ? "probability" : "simple");

    // Start game
    bloc.add(NewGame(difficulty: difficulty));
    // Wait for state update
    await Future.delayed(Duration.zero);

    // Enable Auto Solver (which triggers moves)
    bloc.add(const ToggleAutoSolver());

    final completer = Completer<GameResult>();

    final subscription = bloc.stream.listen((state) {
      if (state.status == GameStateType.won ||
          state.status == GameStateType.lost) {
        if (!completer.isCompleted) {
          completer.complete(GameResult(
            won: state.status == GameStateType.won,
            duration: state.accumulatedDuration,
            revealedTiles: state.revealedTiles,
          ));
        }
      }
    });

    GameResult result = await completer.future
        .timeout(const Duration(seconds: 60), onTimeout: () {
      return GameResult(won: false, duration: Duration.zero, revealedTiles: 0);
    });

    // Disable auto solver and wait for it to settle before closing
    if (bloc.state.autoSolverEnabled) {
      bloc.add(const ToggleAutoSolver());
      await bloc.stream.firstWhere((s) => !s.autoSolverEnabled).timeout(
            const Duration(milliseconds: 500),
            onTimeout: () => bloc.state,
          );
    }

    processor.removeAllTasks();
    await subscription.cancel();
    await bloc.close();

    return result;
  }

  Future<void> runComparison(
      GameDifficulty difficulty, String difficultyName) async {
    int iterations = 100;
    final stopwatch = Stopwatch()..start();

    // Create two separate processors (which means two separate contexts)
    Scheduler.shared.period = 0;
    final defaultProcessor = Processor();
    final probProcessor = Processor();

    log.info("\n--- $difficultyName ($iterations games) ---");
    log.info("Running with Simple Guesser...");
    List<GameResult> defaultResults = [];
    for (int i = 0; i < iterations; i++) {
      defaultResults.add(await runGame(false, defaultProcessor, difficulty));
      if ((i + 1) % 25 == 0) log.info("Completed ${i + 1}");
    }

    log.info("Running with Probability Guesser...");
    List<GameResult> probResults = [];
    for (int i = 0; i < iterations; i++) {
      probResults.add(await runGame(true, probProcessor, difficulty));
      if ((i + 1) % 25 == 0) log.info("Completed ${i + 1}");
    }

    stopwatch.stop();
    log.info("Total time: ${stopwatch.elapsed}");

    // Calculate stats
    var defaultWins = defaultResults.where((r) => r.won).length;
    var defaultAvgRevealed = defaultResults.isEmpty
        ? 0
        : defaultResults.map((r) => r.revealedTiles).reduce((a, b) => a + b) /
            defaultResults.length;

    var probWins = probResults.where((r) => r.won).length;
    var probAvgRevealed = probResults.isEmpty
        ? 0
        : probResults.map((r) => r.revealedTiles).reduce((a, b) => a + b) /
            probResults.length;

    log.info("Results ($difficultyName):");
    log.info("Simple Guesser:");
    log.info(
        "  Wins: $defaultWins / $iterations (${(defaultWins / iterations * 100).toStringAsFixed(1)}%)");
    log.info("  Avg Revealed: ${defaultAvgRevealed.toStringAsFixed(1)}");

    log.info("Probability Guesser:");
    log.info(
        "  Wins: $probWins / $iterations (${(probWins / iterations * 100).toStringAsFixed(1)}%)");
    log.info("  Avg Revealed: ${probAvgRevealed.toStringAsFixed(1)}");
  }

  test("Compare Solvers - Beginner", () async {
    await runComparison(GameDifficulty.beginner, "Beginner");
  });

  test("Compare Solvers - Intermediate", () async {
    await runComparison(GameDifficulty.intermediate, "Intermediate");
  });

  test("Compare Solvers - Expert", () async {
    await runComparison(GameDifficulty.expert, "Expert");
  });
}

class GameResult {
  final bool won;
  final Duration duration;
  final int revealedTiles;

  GameResult(
      {required this.won, required this.duration, required this.revealedTiles});
}
