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

  group("GameBloc", () {
    late GameBloc gameBloc;
    late Processor processor;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // Initialize Pref service to avoid LateInitializationError
      await Pref.service.init("test_prefix");
      processor = Processor();
      Scheduler.shared.period = 0;
      gameBloc = GameBloc(
        processor: processor,
      );
    });

    tearDown(() {
      gameBloc.close();
    });

    test("initial state is correct", () {
      expect(gameBloc.state.status, GameStateType.notStarted);
      expect(gameBloc.state.difficulty, GameDifficulty.beginner);
    });

    test("Flood fill reveals entire area on 0 mines (Custom 5x5)", () async {
      // 0 mines ensures board is empty (all '0's).
      // Probe 0 should reveal all 25 tiles.
      gameBloc.add(NewGame(
          difficulty: GameDifficulty.custom(width: 5, height: 5, mines: 0)));
      await Future.delayed(Duration(milliseconds: 50));

      final tile = gameBloc.state.tiles[0];
      gameBloc.add(Probe(model: tile));

      await Future.delayed(Duration(milliseconds: 50));

      expect(gameBloc.state.revealedTiles, equals(25));
      expect(gameBloc.state.status, equals(GameStateType.won));
    });

    test("Clicking a mine results in loss", () async {
      // 5x5 with 10 mines.
      gameBloc.add(NewGame(
          difficulty: GameDifficulty.custom(width: 5, height: 5, mines: 10)));
      await Future.delayed(Duration(milliseconds: 50));

      // 1. Probe tile 0 to start game (guaranteed safe)
      final startTile = gameBloc.state.tiles[0];
      gameBloc.add(Probe(model: startTile));
      await Future.delayed(Duration(milliseconds: 50));

      expect(gameBloc.state.status, GameStateType.started);

      // 2. Find a tile that HAS a mine and is NOT revealed
      // (Start probe might have revealed neighbors, so we check tile state too)
      final mineTile = gameBloc.state.tiles.firstWhere(
          (t) => t.hasMine && t.state == TileStateType.notPressed,
          orElse: () => throw Exception("No reachable mine found"));

      // 3. Probe the mine
      gameBloc.add(Probe(model: mineTile));
      await Future.delayed(Duration(milliseconds: 50));

      expect(gameBloc.state.status, equals(GameStateType.lost));
    });
  });
}
