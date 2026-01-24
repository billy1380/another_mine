import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/model/tile_state_type.dart";
import "package:another_mine/services/pref.dart";
import "package:flutter_test/flutter_test.dart";
import "package:main_thread_processor/main_thread_processor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("AutoSolver Restart Test", () {
    late GameBloc gameBloc;
    late Processor processor;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      ServiceDiscovery.instance.register(Pref("test_prefix"));
      await ServiceDiscovery.instance.init();

      processor = Processor();
      Scheduler.shared.period = 0;
      gameBloc = GameBloc(
        processor: processor,
        lostGamePause: 0,
      );
    });

    tearDown(() async {
      processor.removeAllTasks();
      await gameBloc.close();
    });

    test("AutoSolver restarts game after loss", () async {
      gameBloc.add(NewGame(
          difficulty: GameDifficulty.custom(width: 5, height: 5, mines: 5)));
      await Future.delayed(Duration.zero);

      final startTile = gameBloc.state.tiles[0];
      gameBloc.add(Probe(model: startTile));
      await Future.delayed(Duration.zero);

      final mineTile = gameBloc.state.tiles
          .firstWhere((t) => t.hasMine && t.state == TileStateType.notPressed);
      gameBloc.add(Probe(model: mineTile));
      await Future.delayed(Duration.zero);

      expect(gameBloc.state.status, GameStateType.lost);

      gameBloc.add(const ToggleAutoSolver());

      await Future.delayed(const Duration(milliseconds: 50));

      expect(gameBloc.state.status, isNot(GameStateType.lost),
          reason: "Game should have restarted from lost state");
    });

    test("AutoSolver stops (disabled) after win", () async {
      gameBloc.add(const ToggleAutoSolver());
      await Future.delayed(Duration.zero);

      gameBloc.add(NewGame(
          difficulty: GameDifficulty.custom(width: 20, height: 20, mines: 1)));

      await Future.delayed(const Duration(milliseconds: 1000));
      expect(gameBloc.state.status, GameStateType.won,
          reason: "Game should be won");

      expect(gameBloc.state.autoSolverEnabled, isFalse,
          reason: "AutoSolver should be disabled after win");

      await Future.delayed(const Duration(milliseconds: 100));
      expect(gameBloc.state.status, GameStateType.won,
          reason: "Game should stay in won state");
    });
  });
}
