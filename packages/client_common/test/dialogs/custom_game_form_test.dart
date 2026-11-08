import "package:another_mine_common/another_mine_common.dart";
import "package:test/test.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "package:willshex_embedding/willshex_embedding.dart";

DialogChange value(String id, Object v) =>
    DialogChange(id, DialogChangeKind.value, value: v);

T control<T extends DialogControl>(DialogRequest request, String id) {
  for (final DialogControl c in request.controls) {
    if (c is DialogRow) {
      for (final DialogControl child in c.children) {
        if (child.id == id) return child as T;
      }
    } else if (c.id == id) {
      return c as T;
    }
  }
  throw StateError("no control $id");
}

void main() {
  group("CustomGameForm", () {
    test("starts on the board it is given", () {
      final form = CustomGameForm(GameDifficulty.expert);
      final request = form.request();

      expect(request.title, "Custom game");
      expect(control<DialogSlider>(request, "width").value, 30);
      expect(control<DialogSlider>(request, "height").value, 16);
      expect(control<DialogSlider>(request, "mines").value, 99);
    });

    test("keeps a board within what the form allows", () {
      final form = CustomGameForm(
        const GameDifficulty(width: 400, height: 1, mines: 9999, name: "x"),
      );

      expect(form.width, CustomGame.maxWidth);
      expect(form.height, CustomGame.minHeight);
      expect(form.mines, CustomGame.maxMinesFor(form.width, form.height));
    });

    test("a preset board is named, a custom one is offered as custom", () {
      final preset = CustomGameForm(GameDifficulty.beginner).request();
      final custom = CustomGameForm(
        GameDifficulty.custom(width: 12, height: 12, mines: 20),
      ).request();

      expect(control<DialogChoice>(preset, "preset").value, "beginner");
      expect(
        control<DialogChoice>(preset, "preset").options.map((o) => o.value),
        ["beginner", "intermediate", "expert"],
      );
      expect(control<DialogChoice>(custom, "preset").value, "custom");
      expect(
        control<DialogChoice>(custom, "preset").options.first.label,
        "Custom",
      );
    });

    test("the traffic light follows the mine density", () {
      int lit(GameDifficulty d) =>
          control<DialogIndicator>(CustomGameForm(d).request(), "rag").active!;

      expect(lit(GameDifficulty.beginner), 0);
      expect(lit(GameDifficulty.intermediate), 1);
      expect(lit(GameDifficulty.expert), 2);
    });

    test("choosing a preset sets the whole board", () {
      final form = CustomGameForm(GameDifficulty.beginner);

      final next = form.request().onChanged!(value("preset", "expert"))!;

      expect(control<DialogSlider>(next, "width").value, 30);
      expect(control<DialogSlider>(next, "height").value, 16);
      expect(control<DialogSlider>(next, "mines").value, 99);
      expect(control<DialogChoice>(next, "preset").value, "expert");
    });

    test("a slider moves one thing and the mines follow the board size", () {
      final form = CustomGameForm(GameDifficulty.expert);

      final next = form.request().onChanged!(value("width", 5.0))!;

      expect(control<DialogSlider>(next, "width").value, 5);
      // 5 x 16 leaves room for 71 mines at most
      expect(control<DialogSlider>(next, "mines").max, 71);
      expect(control<DialogSlider>(next, "mines").value, 71);
      expect(control<DialogChoice>(next, "preset").value, "custom");
    });

    test("mines cannot go past what the board holds", () {
      final form = CustomGameForm(GameDifficulty.beginner);

      final next = form.request().onChanged!(value("mines", 500.0))!;

      expect(
        control<DialogSlider>(next, "mines").value,
        CustomGame.maxMinesFor(9, 9),
      );
    });

    test("a change to something it does not know changes nothing", () {
      final form = CustomGameForm(GameDifficulty.beginner);

      expect(form.request().onChanged!(value("other", 1.0)), isNull);
    });

    test("it is started or cancelled", () {
      final request = CustomGameForm(GameDifficulty.beginner).request();

      expect(request.cancelAction, isNotNull);
      expect(request.actions.last.id, "start");
      expect(request.actions.last.variant, ActionVariant.primary);
    });
  });

  group("CustomGameForm.ask", () {
    final List<void Function()> answerers = [];

    setUp(() async {
      ServiceDiscovery.instance.reset();
      final pref = Pref("test_", InMemoryPrefStorage());
      await pref.init();
      ServiceDiscovery.instance.register<Pref>(pref);
      AnotherMineDialogs.local.supportsDialogs = true;
    });

    tearDown(() {
      for (final a in answerers) {
        AnotherMineDialogs.local.removeListener(a);
      }
      answerers.clear();
      AnotherMineDialogs.local.supportsDialogs = false;
    });

    void answer(void Function(PendingDialog pending) respond) {
      void answerer() {
        final pending = AnotherMineDialogs.local.state.dialog;

        if (pending != null && !pending.isCompleted) respond(pending);
      }

      answerers.add(answerer);
      AnotherMineDialogs.local.addListener(answerer);
    }

    test("starting answers the board and keeps it for next time", () async {
      answer((pending) {
        pending.change(value("width", 20.0));
        pending.change(value("height", 12.0));
        pending.change(value("mines", 40.0));
        pending.complete(const DialogResult("start"));
      });

      final difficulty = await CustomGameForm.ask();

      expect(difficulty?.width, 20);
      expect(difficulty?.height, 12);
      expect(difficulty?.mines, 40);
      expect(Provider.pref.difficulty.width, 20);
      expect(Provider.pref.difficulty.mines, 40);
    });

    test("cancelling answers nothing and keeps nothing", () async {
      answer((pending) {
        pending.change(value("width", 20.0));
        pending.complete(const DialogResult("cancel"));
      });

      expect(await CustomGameForm.ask(), isNull);
      expect(Provider.pref.difficulty.width, GameDifficulty.beginner.width);
    });

    test("starts on the board last played", () async {
      await Provider.pref.setInt("width", 16);
      await Provider.pref.setInt("height", 16);
      await Provider.pref.setInt("mines", 40);
      late DialogRequest asked;
      answer((pending) {
        asked = pending.request;
        pending.complete();
      });

      await CustomGameForm.ask();

      expect(control<DialogSlider>(asked, "width").value, 16);
      expect(control<DialogChoice>(asked, "preset").value, "intermediate");
    });
  });
}
