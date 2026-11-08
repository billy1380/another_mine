import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/widgets/local_dialog_host.dart";
import "package:another_mine_flutter/widgets/scores_list.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

void main() {
  setUp(() async {
    final ServiceDiscovery discovery = ServiceDiscovery.instance;
    discovery.reset();

    final Pref pref = Pref("test_", InMemoryPrefStorage());
    await pref.init();
    discovery.register<Pref>(pref);

    // no path: a host that keeps no scores, so every category is empty
    discovery.register<ScoreKeeper>(ScoreKeeper(null, pref));
    await discovery.resolve<ScoreKeeper>().init();
  });

  Future<void> show(WidgetTester tester) {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    return tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: LocalDialogHost(
          navigatorKey: navigatorKey,
          child: const Scaffold(body: ScoresList()),
        ),
      ),
    );
  }

  testWidgets("has a tab for every category", (tester) async {
    await show(tester);
    await tester.pumpAndSettle();

    expect(find.byType(Tab), findsNWidgets(ScoreCategory.values.length));
    expect(find.text("Beginner"), findsOneWidget);
    expect(find.text("Custom Hard"), findsOneWidget);
  });

  testWidgets("starts on the category of the game last played", (tester) async {
    await Provider.pref.setInt("width", GameDifficulty.expert.width);
    await Provider.pref.setInt("height", GameDifficulty.expert.height);
    await Provider.pref.setInt("mines", GameDifficulty.expert.mines);

    await show(tester);
    await tester.pumpAndSettle();

    final TabBar bar = tester.widget(find.byType(TabBar));
    expect(
      bar.controller ??
          DefaultTabController.of(tester.element(find.byType(TabBar))),
      isA<TabController>().having(
        (c) => c.index,
        "index",
        ScoreCategory.expert.index,
      ),
    );
  });

  testWidgets("a tab can be picked and shows its own scores", (tester) async {
    await show(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text("Custom Medium"));
    await tester.pumpAndSettle();

    expect(find.text("No scores yet."), findsOneWidget);
  });

  group("deleting", () {
    setUp(() async {
      final ServiceDiscovery discovery = ServiceDiscovery.instance;
      discovery.reset();

      final Pref pref = Pref("test_", InMemoryPrefStorage());
      await pref.init();
      discovery.register<Pref>(pref);
      discovery.register<ScoreKeeper>(_MemoryScoreKeeper(pref, [30, 40]));
    });

    testWidgets("a score is deleted once it is confirmed", (tester) async {
      await show(tester);
      await tester.pumpAndSettle();

      expect(find.text("30 s"), findsOneWidget);
      expect(find.text("40 s"), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      expect(find.text("Delete score?"), findsOneWidget);

      await tester.tap(find.text("Delete"));
      await tester.pumpAndSettle();

      expect(find.text("30 s"), findsNothing);
      expect(find.text("40 s"), findsOneWidget);
    });

    testWidgets("cancelling keeps the score", (tester) async {
      await show(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();

      expect(find.text("30 s"), findsOneWidget);
    });

    testWidgets("all the scores of a category can be deleted", (tester) async {
      await show(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text("Delete all Beginner scores"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Delete"));
      await tester.pumpAndSettle();

      expect(find.text("No scores yet."), findsOneWidget);
    });
  });
}

/// A score keeper that keeps Beginner scores in memory, so that the list can be
/// tested without a store (the store itself is tested in `another_mine_common`).
class _MemoryScoreKeeper extends ScoreKeeper {
  final List<LocalScore> _scores;

  _MemoryScoreKeeper(Pref pref, List<int> seconds)
    : _scores = [
        for (int i = 0; i < seconds.length; i++)
          LocalScore(
            id: i + 1,
            name: "billy",
            seconds: seconds[i],
            category: ScoreCategory.beginner,
            width: 9,
            height: 9,
            mines: 10,
            solver: Solver.human,
            when: DateTime(2026, 11, 7, 13, 42),
          ),
      ],
      super("memory", pref);

  @override
  Future<List<LocalScore>> top(ScoreCategory category) async =>
      category == ScoreCategory.beginner ? List.of(_scores) : const [];

  @override
  Future<void> remove(LocalScore score) async =>
      _scores.removeWhere((s) => s.id == score.id);

  @override
  Future<void> clearCategory(ScoreCategory category) async {
    if (category == ScoreCategory.beginner) _scores.clear();
  }
}
