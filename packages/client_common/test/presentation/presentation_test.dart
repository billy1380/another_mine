import "dart:io";

import "package:another_mine_common/another_mine_common.dart";
import "package:mine_images/mine_images.dart";
import "package:test/test.dart";

void main() {
  group("Colour", () {
    test("splits and joins ARGB", () {
      const Colour colour = Colour.fromARGB(0x80, 0x12, 0x34, 0x56);

      expect(colour.argb, 0x80123456);
      expect(colour.alpha, 0x80);
      expect(colour.red, 0x12);
      expect(colour.green, 0x34);
      expect(colour.blue, 0x56);
    });

    test("luminance runs from black to white", () {
      expect(const Colour(0xFF000000).computeLuminance(), 0.0);
      expect(const Colour(0xFFFFFFFF).computeLuminance(), closeTo(1.0, 1e-9));
    });

    test("formats for CSS", () {
      expect(const Colour(0xFF2E3436).hex, "#2e3436");
      expect(
        const Colour.fromARGB(255, 46, 52, 54).css,
        "rgba(46, 52, 54, 1.000)",
      );
    });
  });

  group("images", () {
    test("tiles that touch mines show their number", () {
      expect(tileImage(TileStateType.three), MineImage.three);
      expect(tileImage(TileStateType.notPressed), isNull);
      expect(tileImage(TileStateType.revealedSafe), isNull);
    });

    test("the face follows the game", () {
      expect(faceImage(GameStateType.won), MineImage.cool);
      expect(faceImage(GameStateType.lost), MineImage.restin);
      expect(faceImage(GameStateType.started), MineImage.well);
    });

    test("counters pad to the number of places", () {
      expect(counterImages(7), [MineImage.counter0, MineImage.counter7]);
      expect(counterImages(42, digits: 3), [
        MineImage.counter0,
        MineImage.counter4,
        MineImage.counter2,
      ]);
      expect(counterImages(123, digits: 2), [
        MineImage.counter2,
        MineImage.counter3,
      ]);
    });

    test("every image has a file", () {
      for (final MineImage image in MineImage.values) {
        expect(
          File("../mine_images/assets/images/${image.fileName}").existsSync(),
          isTrue,
          reason: image.fileName,
        );
      }
    });
  });

  group("probability", () {
    test("only unrevealed tiles show it, and not when tiny", () {
      expect(showsProbability(TileStateType.notPressed, 0.5), isTrue);
      expect(showsProbability(TileStateType.unsure, 0.5), isTrue);
      expect(showsProbability(TileStateType.one, 0.5), isFalse);
      expect(showsProbability(TileStateType.notPressed, 0.001), isFalse);
      expect(showsProbability(TileStateType.notPressed, null), isFalse);
    });

    test("is lighter on dark tiles than on light ones", () {
      final Colour onDark = probabilityColour(0.9, const Colour(0xFF000000));
      final Colour onLight = probabilityColour(0.9, const Colour(0xFFFFFFFF));

      expect(
        onDark.computeLuminance(),
        greaterThan(onLight.computeLuminance()),
      );
    });
  });

  group("custom game", () {
    test("leaves room for a first click", () {
      expect(CustomGame.maxMinesFor(9, 9), 72);
      expect(CustomGame.maxMinesFor(5, 5), 16);
    });

    test("keeps mines within bounds", () {
      expect(CustomGame.clampMines(500, 9, 9), 72);
      expect(CustomGame.clampMines(0, 9, 9), 1);
    });

    test("names the standard difficulties", () {
      expect(CustomGame.nameFor(9, 9, 10), "Beginner");
      expect(CustomGame.nameFor(9, 9, 11), "Custom");
    });

    test("grades mine density", () {
      expect(ragFor(9, 9, 10), Rag.green);
      expect(ragFor(16, 16, 40), Rag.amber);
      expect(ragFor(30, 16, 99), Rag.red);
    });
  });

  group("game routes", () {
    test("round trip a difficulty", () {
      final String path = GameRoutes.game(GameDifficulty.expert);
      expect(path, "/game/30/16/99");

      expect(
        GameRoutes.difficultyFrom({
          "width": "30",
          "height": "16",
          "mines": "99",
        }),
        GameDifficulty.expert,
      );
    });

    test("fall back to beginner for rubbish", () {
      expect(
        GameRoutes.difficultyFrom({"width": "x"}),
        GameDifficulty.beginner,
      );
    });
  });

  group("mines remaining", () {
    test("counts down from all the mines and stops at zero", () {
      final GameState start = GameState.initial(
        GameDifficulty.beginner,
        const Colour(0xFF000000),
      );

      expect(start.minesRemaining, 10);
      expect(start.copyWith(minesMarked: 3).minesRemaining, 7);
      expect(start.copyWith(minesMarked: 12).minesRemaining, 0);
    });
  });

  group("InMemoryPrefStorage", () {
    test("stores and removes values", () async {
      final InMemoryPrefStorage storage = InMemoryPrefStorage({"a": 1});

      expect(storage.getInt("a"), 1);
      await storage.setBool("b", true);
      expect(storage.getBool("b"), isTrue);
      expect(await storage.remove("b"), isTrue);
      expect(storage.getBool("b"), isNull);
    });
  });
}
