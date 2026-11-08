import "dart:convert";

import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_common/model/colour.dart";
import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/model/game_state_type.dart";
import "package:another_mine_common/scores/game_recorder.dart";
import "package:another_mine_common/scores/score_keeper.dart";
import "package:another_mine_common/scores/score_submitter.dart";
import "package:another_mine_common/services/pref.dart";
import "package:another_mine_common/services/pref_storage.dart";
import "package:archive/archive.dart";
import "package:test/test.dart";

GameState fresh() =>
    GameState.initial(GameDifficulty.beginner, const Colour(0xFF000000));

void main() {
  group("GameRecorder", () {
    test("records moves, pauses and mode changes in order", () {
      DateTime now = DateTime(2026);
      final GameRecorder recorder = GameRecorder(now: () => now);
      final GameState state = fresh();
      final tile = state.tiles.firstWhere((t) => !t.hasMine);

      recorder.record(Probe(model: tile), state);
      now = now.add(const Duration(milliseconds: 250));
      recorder.record(const ToggleProbabilities(), state);
      now = now.add(const Duration(milliseconds: 250));
      recorder.record(const PauseGame(), state);

      expect(recorder.events, [
        [0, "p", tile.index],
        [250, "prob", 1],
        [500, "pause"],
      ]);
    });

    test("records nothing for a game the solver played any of", () {
      final GameRecorder recorder = GameRecorder();
      final GameState state = fresh().copyWith(solverUsed: true);

      recorder.record(Probe(model: state.tiles.first), state);

      expect(recorder.events, isEmpty);
    });

    test("does not record the move that is replayed after a mine is moved", () {
      final GameRecorder recorder = GameRecorder();
      final GameState state = fresh();
      final mine = state.tiles.firstWhere((t) => t.hasMine);

      recorder.record(Probe(model: mine), state);

      expect(recorder.events, isEmpty);
    });
  });

  group("ScoreSubmitter", () {
    late Pref pref;

    setUp(() async {
      pref = Pref("test_", InMemoryPrefStorage());
      await pref.init();
      await pref.setBool(Pref.keyRemoteScoresEnabled, true);
      await pref.setString(Pref.keyPlayerName, "billy1380");
    });

    WonGame win(GameDifficulty difficulty, {int seconds = 40}) => WonGame.from(
      fresh().copyWith(
        status: GameStateType.won,
        difficulty: difficulty,
        accumulatedDuration: Duration(seconds: seconds),
      ),
      pref,
    )!;

    test("sends only human wins that are kept online and believable", () {
      final ScoreSubmitter submitter = ScoreSubmitter(pref);

      expect(submitter.shouldSend(win(GameDifficulty.beginner)), isTrue);
      expect(
        submitter.shouldSend(win(GameDifficulty.beginner, seconds: 0)),
        isFalse,
      );
      expect(
        submitter.shouldSend(
          win(GameDifficulty.custom(width: 30, height: 30, mines: 10)),
        ),
        isFalse,
        reason: "Custom Easy stays local",
      );
    });

    test("encodes the recording as gzip then base64 JSON", () {
      final String data = ScoreSubmitter.encode(win(GameDifficulty.expert));
      final Map<String, dynamic> json = jsonDecode(
        utf8.decode(GZipDecoder().decodeBytes(base64.decode(data))),
      );

      expect(json["game"], "anothermine");
      expect(json["version"], 2);
      expect(json["width"], 30);
      expect(json["events"], isList);
    });
  });
}
