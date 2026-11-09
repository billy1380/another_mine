import "package:another_mine_flutter/widgets/game_body.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets(
    "a long press on the bottom row flags without scrolling the map",
    (tester) async {
      final ScrollController horizontal = ScrollController();
      final ScrollController vertical = ScrollController();
      int longPresses = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 300,
                height: 300,
                child: GameScrollable(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  contentSize: const Size(1200, 300),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () => longPresses++,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // a tile at the right of the bottom row, away from the scrollbar's thumb
      await tester.longPressAt(const Offset(280, 290));
      await tester.pumpAndSettle();

      expect(longPresses, 1);
      expect(horizontal.offset, 0);
    },
  );
}
