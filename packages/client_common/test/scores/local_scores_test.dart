import "dart:io";

import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/scores/local_score.dart";
import "package:another_mine_common/scores/local_scores.dart";
import "package:another_mine_common/scores/score_category.dart";
import "package:test/test.dart";

LocalScore score(
  String name,
  int seconds, {
  GameDifficulty difficulty = GameDifficulty.beginner,
  Solver solver = Solver.human,
  DateTime? when,
}) => LocalScore(
  name: name,
  seconds: seconds,
  category: ScoreCategory.forDifficulty(difficulty),
  width: difficulty.width,
  height: difficulty.height,
  mines: difficulty.mines,
  solver: solver,
  when: when ?? DateTime.fromMillisecondsSinceEpoch(1000),
);

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync("local_scores_"));
  tearDown(() => dir.deleteSync(recursive: true));

  LocalScores open({int retained = 20}) =>
      LocalScores("${dir.path}/scores", retained: retained);

  test("a score is kept and listed with its player and board", () async {
    final scores = open();

    expect(await scores.add(score("billy", 42)), 1);

    final top = await scores.top(ScoreCategory.beginner);
    expect(top, hasLength(1));
    expect(top.single.name, "billy");
    expect(top.single.seconds, 42);
    expect(top.single.board, "Beginner");
    expect(top.single.width, 9);
    expect(top.single.mines, 10);
  });

  test("scores come back best first and a tie ranks after the first", () async {
    final scores = open();

    expect(await scores.add(score("a", 50)), 1);
    expect(await scores.add(score("b", 30)), 1);
    expect(await scores.add(score("c", 50)), 3);

    final top = await scores.top(ScoreCategory.beginner);
    expect(top.map((s) => s.name), ["b", "a", "c"]);
  });

  test("each category keeps its own scores", () async {
    final scores = open();

    await scores.add(score("a", 10));
    await scores.add(score("b", 90, difficulty: GameDifficulty.expert));

    expect((await scores.top(ScoreCategory.beginner)).map((s) => s.name), [
      "a",
    ]);
    expect((await scores.top(ScoreCategory.expert)).map((s) => s.name), ["b"]);
    expect(await scores.top(ScoreCategory.hard), isEmpty);
  });

  test("only the best are retained and a worse score is not kept", () async {
    final scores = open(retained: 2);

    await scores.add(score("a", 10));
    await scores.add(score("b", 20));

    expect(await scores.add(score("c", 30)), isNull);
    expect(await scores.add(score("d", 15)), 2);

    final top = await scores.top(ScoreCategory.beginner);
    expect(top.map((s) => s.name), ["a", "d"]);
  });

  test("a custom board is filed by density and keeps its board", () async {
    final scores = open();
    final board = GameDifficulty.custom(width: 10, height: 10, mines: 20);

    await scores.add(score("a", 77, difficulty: board, solver: Solver.simple));

    final top = await scores.top(ScoreCategory.hard);
    expect(top.single.board, "Custom 20 mines on 10 x 10");
    expect(top.single.solver, Solver.simple);
  });

  test("scores are still there when the store is opened again", () async {
    await open().add(score("a", 11));

    expect((await open().top(ScoreCategory.beginner)).single.seconds, 11);
  });

  test("the same name is one player", () async {
    final scores = open();

    await scores.add(score("a", 11));
    await scores.add(score("a", 12));

    final top = await scores.top(ScoreCategory.beginner);
    expect(top.map((s) => s.name), ["a", "a"]);
  });

  test("clear forgets everything", () async {
    final scores = open();

    await scores.add(score("a", 11));
    await scores.clear();

    expect(await scores.top(ScoreCategory.beginner), isEmpty);
  });

  test("a stored score has an id and can be removed alone", () async {
    final scores = open();

    await scores.add(score("a", 11));
    await scores.add(score("b", 22));

    final top = await scores.top(ScoreCategory.beginner);
    expect(top.every((s) => s.id != null), isTrue);

    await scores.remove(top.first);

    expect((await scores.top(ScoreCategory.beginner)).map((s) => s.name), [
      "b",
    ]);
  });

  test("removing a score that was never stored does nothing", () async {
    final scores = open();

    await scores.add(score("a", 11));
    await scores.remove(score("a", 11));

    expect(await scores.top(ScoreCategory.beginner), hasLength(1));
  });

  test("clearing a category leaves the others", () async {
    final scores = open();

    await scores.add(score("a", 11));
    await scores.add(score("b", 22, difficulty: GameDifficulty.expert));
    await scores.clearCategory(ScoreCategory.beginner);

    expect(await scores.top(ScoreCategory.beginner), isEmpty);
    expect(await scores.top(ScoreCategory.expert), hasLength(1));
  });
}
