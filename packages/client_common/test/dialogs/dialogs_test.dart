import "package:another_mine_common/another_mine_common.dart";
import "package:mine_images/mine_images.dart";
import "package:test/test.dart";
import "package:willshex_embedding/willshex_embedding.dart";

const WonGame game = WonGame(
  seconds: 42,
  width: 9,
  height: 9,
  mines: 10,
  category: ScoreCategory.beginner,
  solver: Solver.human,
);

final LocalScore score = LocalScore(
  name: "billy",
  seconds: 37,
  category: ScoreCategory.beginner,
  width: 9,
  height: 9,
  mines: 10,
  solver: Solver.human,
  when: DateTime(2026, 11, 7, 13, 42),
);

final List<void Function()> _answerers = [];

/// Answers whatever the game asks of its own host, as its client would, until
/// the test is over.
void answerLocal(DialogResult? Function(DialogRequest request) answer) {
  void answerer() {
    final PendingDialog? pending = AnotherMineDialogs.local.state.dialog;

    if (pending != null && !pending.isCompleted) {
      pending.complete(answer(pending.request));
    }
  }

  _answerers.add(answerer);
  AnotherMineDialogs.local.addListener(answerer);
}

void main() {
  tearDown(() {
    for (final void Function() answerer in _answerers) {
      AnotherMineDialogs.local.removeListener(answerer);
    }
    _answerers.clear();
    AnotherMineDialogs.hostSession = null;
    AnotherMineDialogs.local.supportsDialogs = false;
  });

  group("AnotherMineDialogs", () {
    test("asks the host when it draws dialogs", () async {
      final host = EmbeddingController()..supportsDialogs = true;
      AnotherMineDialogs.hostSession = host.createPageSession();
      AnotherMineDialogs.local.supportsDialogs = true;

      final answer = AnotherMineDialogs.ask(
        DialogRequest.confirm(title: "Sure?"),
      );

      expect(host.state.dialog, isNotNull);
      expect(AnotherMineDialogs.local.state.dialog, isNull);

      host.state.dialog!.complete(const DialogResult("confirm"));
      expect((await answer)?.actionId, "confirm");
    });

    test("asks its own host when the embedding host draws none", () async {
      final host = EmbeddingController();
      AnotherMineDialogs.hostSession = host.createPageSession();
      AnotherMineDialogs.local.supportsDialogs = true;

      final answer = AnotherMineDialogs.ask(
        DialogRequest.confirm(title: "Sure?"),
      );

      expect(host.state.dialog, isNull);
      expect(AnotherMineDialogs.local.state.dialog, isNotNull);

      AnotherMineDialogs.local.state.dialog!.complete();
      expect(await answer, isNull);
    });

    test("asks its own host when there is no embedding host", () async {
      AnotherMineDialogs.local.supportsDialogs = true;

      final answer = AnotherMineDialogs.ask(
        DialogRequest.confirm(title: "Sure?"),
      );

      expect(AnotherMineDialogs.local.state.dialog, isNotNull);

      AnotherMineDialogs.local.state.dialog!.complete(
        const DialogResult("confirm"),
      );
      expect((await answer)?.actionId, "confirm");
    });

    test("answers nothing when nothing can draw it", () async {
      expect(
        await AnotherMineDialogs.ask(DialogRequest.confirm(title: "Sure?")),
        isNull,
      );
    });
  });

  group("ScoreDialogs", () {
    setUp(() => AnotherMineDialogs.local.supportsDialogs = true);

    test("asks whose score it is, with the time and the place", () async {
      late DialogRequest asked;
      answerLocal((request) {
        asked = request;

        return const DialogResult("save", {"name": "billy"});
      });

      final String? name = await ScoreDialogs.askName(
        game,
        3,
        initialName: "old",
      );

      expect(name, "billy");
      expect(asked.title, "You won!");
      expect(asked.message, contains("42 seconds on Beginner"));
      expect(asked.message, contains("Place 3 in Beginner"));
      expect(asked.fields.single.initialValue, "old");
      expect(asked.fields.single.isRequired, isTrue);
    });

    test("shows the medal for the first three places, else the face", () {
      for (final (place, image) in [
        (1, MineImage.medal1),
        (2, MineImage.medal2),
        (3, MineImage.medal3),
        (4, MineImage.dunno),
        (20, MineImage.dunno),
      ]) {
        final shown = ScoreDialogs.imageFor(place);

        expect(shown.asset, image.asset, reason: "place $place");
        expect(shown.package, MineImage.package);
      }
    });

    test("the win question carries the picture of its place", () async {
      late DialogRequest asked;
      answerLocal((request) {
        asked = request;

        return null;
      });

      await ScoreDialogs.askName(game, 2);

      expect(asked.image?.asset, MineImage.medal2.asset);
    });

    test("the best place says so", () async {
      late DialogRequest asked;
      answerLocal((request) {
        asked = request;

        return null;
      });

      await ScoreDialogs.askName(game, 1);

      expect(asked.message, contains("A new best time!"));
    });

    test("a known player is congratulated, not asked a name", () async {
      late DialogRequest asked;
      answerLocal((request) {
        asked = request;

        return const DialogResult("ok");
      });

      final String? name = await ScoreDialogs.askName(
        game,
        3,
        initialName: "billy",
        askForName: false,
      );

      expect(name, "billy");
      expect(asked.fields, isEmpty);
    });

    test("skipping, or saving no name, keeps nothing", () async {
      answerLocal((request) => DialogResult(request.cancelAction!.id));

      expect(await ScoreDialogs.askName(game, 1), isNull);
    });

    test("deleting is a destructive question that only yes confirms", () async {
      late DialogRequest asked;
      answerLocal((request) {
        asked = request;

        return const DialogResult("confirm");
      });

      expect(await ScoreDialogs.confirmDeleteScore(score), isTrue);
      expect(asked.title, "Delete score?");
      expect(asked.message, contains("billy's 37 s on Beginner"));
      expect(asked.actions.last.variant, ActionVariant.destructive);
    });

    test("cancelling a delete does not delete", () async {
      answerLocal((request) => DialogResult(request.cancelAction!.id));

      expect(await ScoreDialogs.confirmDeleteScore(score), isFalse);
      expect(await ScoreDialogs.confirmDeleteAll("Beginner"), isFalse);
    });

    test("deleting everything names the category", () async {
      late DialogRequest asked;
      answerLocal((request) {
        asked = request;

        return const DialogResult("confirm");
      });

      expect(await ScoreDialogs.confirmDeleteAll("Beginner"), isTrue);
      expect(asked.message, contains("Every Beginner score"));
    });
  });
}
