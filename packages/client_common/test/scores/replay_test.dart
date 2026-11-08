import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_common/scores/score_submitter.dart";
import "package:main_thread_processor/main_thread_processor.dart";
import "package:test/test.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

// 3 x 3 with the only mine in the middle (tile 4), won by revealing the rest
final List<List<Object>> events = [
  [0, "prob", 1],
  [200, "p", 0],
  [400, "pause"],
  [60000, "resume"],
  for (final int tile in [1, 2, 3, 5, 6, 7, 8]) [60000 + tile * 100, "p", tile],
];

Recording recorded() => Recording.decode(
  ScoreSubmitter.encode(
    WonGame(
      seconds: 3,
      width: 3,
      height: 3,
      mines: 1,
      category: ScoreCategory.easy,
      solver: Solver.human,
      layout: "EAA=",
      events: events,
    ),
  ),
);

void main() {
  setUp(() async {
    ServiceDiscovery.instance.register(Pref("test_", InMemoryPrefStorage()));
    await ServiceDiscovery.instance.init();
    Scheduler.shared.period = 0;
  });

  Future<void> pump() => Future.delayed(const Duration(milliseconds: 50));

  test("decodes a recording and replays it to the win", () async {
    final ReplayCubit replay = ReplayCubit(recorded());
    await replay.start(autoplay: false);

    // the 60 s pause is waited out for one second only
    expect(replay.state.total, lessThan(3000));

    replay.advanceTo(replay.state.total);
    await pump();

    expect(replay.bloc.state.status, GameStateType.won);
    expect(replay.state.probability, isTrue);
    expect(replay.state.finished, isTrue);

    await replay.close();
  });

  test("plays faster at a higher speed", () async {
    final ReplayCubit replay = ReplayCubit(recorded());
    await replay.start(autoplay: false);

    replay.setSpeed(8);
    replay.play();
    await Future.delayed(const Duration(milliseconds: 400));
    await pump();

    expect(replay.state.finished, isTrue);
    expect(replay.bloc.state.status, GameStateType.won);

    await replay.close();
  });
}
