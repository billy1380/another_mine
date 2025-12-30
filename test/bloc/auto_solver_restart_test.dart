import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/model/tile_state_type.dart";
import "package:another_mine/services/pref.dart";
import "package:flutter_test/flutter_test.dart";
import "package:main_thread_processor/main_thread_processor.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock Processor to avoid actual task scheduling but allow us to see if tasks ARE added?
  // Actually, Processor.shared is a singleton. We might need to handle it or let it run.
  // The GameBloc uses Processor.shared.addTask.
  // If we don't mock it, it runs locally.

  group("AutoSolver Restart Test", () {
    late GameBloc gameBloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Pref.service.init("test_prefix");
      gameBloc = GameBloc();
      Processor.shared.removeAllTasks();
    });

    tearDown(() {
      gameBloc.close();
      Processor.shared.removeAllTasks();
    });

    test("AutoSolver restarts game after loss", () async {
      // 1. Enable Auto Solver
      gameBloc.add(const ToggleAutoSolver());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(gameBloc.state.autoSolverEnabled, isTrue);

      // 2. Start a game with mines (so we can lose)
      gameBloc.add(NewGame(
          difficulty: GameDifficulty.custom(width: 5, height: 5, mines: 5)));
      await Future.delayed(const Duration(milliseconds: 50));

      // 3. Manually find a mine and click it to force a loss
      // We need to probe start first to ensure game is "active" or just click a mine.
      // GameBloc._probe handles first move protection by relocating mine, so first click is safe.
      // We click random safe tile first.

      // Let's rely on state.
      // Wait for auto solver to move?
      // Auto solver uses Processor.
      // Since we enabled it, it might have already made a move.
      // Let's force a loss manually to verify the RESTART logic specifically.

      // Stop the auto solver loop temporarily to inject our deterministic loss?
      // Actually, if we just Probe a mine, it triggers loss.

      // Make sure we have a started game.
      final startTile = gameBloc.state.tiles[0];
      gameBloc.add(Probe(model: startTile)); // Safe start
      await Future.delayed(const Duration(milliseconds: 50));

      // Find a mine
      final mineTile = gameBloc.state.tiles.firstWhere(
          (t) => t.hasMine && t.state == TileStateType.notPressed,
          orElse: () => throw Exception("No reachable mine found"));

      // 4. Probe the mine -> Loss
      gameBloc.add(Probe(model: mineTile));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(gameBloc.state.status, GameStateType.lost);

      // 5. Verify that AutoSolverNextMove was triggered and is waiting to restart.
      // The lostGameAutoSolverPause is 2 seconds.
      // We wait > 2 seconds.

      // Because we are in a test environment with async delays,
      // we need to wait enough time for the Future.delayed in _autoSolverNextMove to complete.
      await Future.delayed(const Duration(seconds: 3));

      // 6. Verify game has restarted (status should be notStarted or started or tiles reset)
      // NewGame resets status to notStarted (or initial).
      // If AutoSolver ran again after restart, it might be Thinking or Started.

      // Check that the mine we clicked is no longer revealedBomb (state reset).
      // Or check status.
      // New Game sets status to GameStateType.notStarted (via initial) then checks auto solver.

      // Ideally, the game state should represent a NEW game.
      // If it restarted, 'refresh' might be 0?
      // Or we can check if the status is NOT lost.
      expect(gameBloc.state.status, isNot(GameStateType.lost));
    });
  });
}
