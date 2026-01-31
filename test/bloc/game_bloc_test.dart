import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/model/tile_state_type.dart";
import "package:another_mine/services/pref.dart";
import "package:another_mine/services/provider.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:main_thread_processor/main_thread_processor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("GameBloc", () {
    late GameBloc gameBloc;
    late Processor processor;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      ServiceDiscovery.instance.register(Pref("test_"));
      await ServiceDiscovery.instance.init();

      processor = Processor();
      Scheduler.shared.period = 0;
      gameBloc = GameBloc(
        processor: processor,
      );
    });

    tearDown(() {
      gameBloc.close();
    });

    Future<void> pump() => Future.delayed(const Duration(milliseconds: 50));

    void expectColor(Color actual, Color expectedBase, double expectedAlpha) {
      expect((actual.r * 255).round(), equals((expectedBase.r * 255).round()),
          reason: "Red component mismatch");
      expect((actual.g * 255).round(), equals((expectedBase.g * 255).round()),
          reason: "Green component mismatch");
      expect((actual.b * 255).round(), equals((expectedBase.b * 255).round()),
          reason: "Blue component mismatch");
      expect((actual.a * 255).round(), equals((expectedAlpha * 255).round()),
          reason: "Alpha component mismatch");
    }

    group("Initialization", () {
      test("initial state is correct", () {
        expect(gameBloc.state.status, GameStateType.notStarted);
        expect(gameBloc.state.difficulty, GameDifficulty.none);
      });
    });

    group("Gameplay", () {
      test("Flood fill reveals entire area on 0 mines (Custom 5x5)", () async {
        gameBloc.add(NewGame(
            difficulty: GameDifficulty.custom(width: 5, height: 5, mines: 0)));
        await pump();

        final tile = gameBloc.state.tiles[0];
        gameBloc.add(Probe(model: tile));

        await pump();

        expect(gameBloc.state.revealedTiles, equals(25));
        expect(gameBloc.state.status, equals(GameStateType.won));
      });

      test("Clicking a mine results in loss", () async {
        gameBloc.add(NewGame(
            difficulty: GameDifficulty.custom(width: 5, height: 5, mines: 10)));
        await pump();

        final startTile = gameBloc.state.tiles[0];
        gameBloc.add(Probe(model: startTile));
        await pump();

        expect(gameBloc.state.status, GameStateType.started);

        final mineTile = gameBloc.state.tiles.firstWhere(
            (t) => t.hasMine && t.state == TileStateType.notPressed,
            orElse: () => throw Exception("No reachable mine found"));

        gameBloc.add(Probe(model: mineTile));
        await pump();

        expect(gameBloc.state.status, equals(GameStateType.lost));
      });
    });

    group("Settings", () {
      test("RefreshSettings updates tile colors and handles disabling",
          () async {
        gameBloc.add(NewGame(difficulty: GameDifficulty.beginner));
        await pump();

        final initialTile = gameBloc.state.tiles[0];
        final initialAlpha = initialTile.colour.a;

        // 1. Enable custom color and change it
        await Provider.pref.setBool(Pref.keyCustomBgEnabled, true);
        const newBaseColor = Color(0xFF123456);
        await Provider.pref
            .setInt(Pref.keyCustomBgColor, newBaseColor.toARGB32());

        gameBloc.add(const RefreshSettings());
        await pump();

        expectColor(
            gameBloc.state.tiles[0].colour, newBaseColor, initialAlpha);

        // 2. Disable custom color - should revert to default grey
        await Provider.pref.setBool(Pref.keyCustomBgEnabled, false);
        gameBloc.add(const RefreshSettings());
        await pump();

        expectColor(gameBloc.state.tiles[0].colour, Pref.defaultBackgroundColour,
            initialAlpha);
      });
    });
  });
}