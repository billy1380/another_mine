import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/widgets/local_dialog_host.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

const WonGame game = WonGame(
  seconds: 42,
  width: 9,
  height: 9,
  mines: 10,
  category: ScoreCategory.beginner,
  solver: Solver.human,
);

void main() {
  tearDown(() {
    // a dialog left waiting would hold up the next test's
    AnotherMineDialogs.local.state.dialog?.complete();
    AnotherMineDialogs.hostSession = null;
    AnotherMineDialogs.local.supportsDialogs = false;
  });

  Future<void> mount(WidgetTester tester) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: LocalDialogHost(
          navigatorKey: navigatorKey,
          child: const Scaffold(body: Text("page")),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets("tells the game it draws dialogs, until it goes", (tester) async {
    await mount(tester);
    expect(AnotherMineDialogs.local.supportsDialogs, isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(AnotherMineDialogs.local.supportsDialogs, isFalse);
  });

  testWidgets("the win question shows the time and place and keeps the name", (
    tester,
  ) async {
    await mount(tester);

    final answer = ScoreDialogs.askName(game, 3, initialName: "");
    await tester.pumpAndSettle();

    expect(find.text("You won!"), findsOneWidget);
    expect(find.textContaining("42 seconds on Beginner"), findsOneWidget);
    expect(find.textContaining("Place 3 in Beginner"), findsOneWidget);

    FilledButton save() =>
        tester.widget(find.widgetWithText(FilledButton, "Save"));
    expect(save().onPressed, isNull);

    await tester.enterText(find.byType(TextField), "  billy ");
    await tester.pump();
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(await answer, "billy");
  });

  testWidgets("save is the default button and skip a plain one", (
    tester,
  ) async {
    await mount(tester);

    ScoreDialogs.askName(game, 1);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, "Save"), findsOneWidget);
    expect(find.widgetWithText(TextButton, "Skip"), findsOneWidget);
    expect(find.widgetWithText(FilledButton, "Skip"), findsNothing);
  });

  Future<AssetImage> shownImage(WidgetTester tester, int place) async {
    await mount(tester);

    ScoreDialogs.askName(game, place);
    await tester.pumpAndSettle();

    return (tester.widget<Image>(find.byType(Image))).image as AssetImage;
  }

  testWidgets("shows the medal of a place that has one", (tester) async {
    final AssetImage image = await shownImage(tester, 1);

    expect(image.assetName, "assets/images/medal1.png");
    expect(image.package, "mine_images");
  });

  testWidgets("shows the face that is not sure past third place", (
    tester,
  ) async {
    final AssetImage image = await shownImage(tester, 7);

    expect(image.assetName, "assets/images/dunno.png");
  });

  testWidgets("skip keeps nothing", (tester) async {
    await mount(tester);

    final answer = ScoreDialogs.askName(game, 1);
    await tester.pumpAndSettle();
    expect(find.textContaining("A new best time!"), findsOneWidget);

    await tester.tap(find.text("Skip"));
    await tester.pumpAndSettle();

    expect(await answer, isNull);
  });

  testWidgets("enter in the name field saves", (tester) async {
    await mount(tester);

    final answer = ScoreDialogs.askName(game, 2);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), "billy");
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(await answer, "billy");
  });

  testWidgets("tapping outside is a skip", (tester) async {
    await mount(tester);

    final answer = ScoreDialogs.askName(game, 2);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(await answer, isNull);
  });
}
