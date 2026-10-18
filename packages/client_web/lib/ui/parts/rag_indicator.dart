import "package:another_mine_common/another_mine_common.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";

/// Three lights showing how hard a mine density is.
class RagIndicator extends StatelessComponent {
  final int width;
  final int height;
  final int mines;

  const RagIndicator({
    super.key,
    required this.width,
    required this.height,
    required this.mines,
  });

  @override
  Component build(BuildContext context) {
    final Rag rag = ragFor(width, height, mines);

    Component light(String colour, bool on) => span(
      attributes: {
        "style":
            "width: 12px; height: 12px; border-radius: 50%;"
            " background-color: ${on ? colour : "#ced4da"};",
      },
      const [],
    );

    return div(
      attributes: {
        "title": "Difficulty: ${rag.name}",
        "style": "display: inline-flex; gap: 4px; align-items: center;",
      },
      [
        light("#198754", rag == Rag.green),
        light("#fd7e14", rag == Rag.amber),
        light("#dc3545", rag == Rag.red),
      ],
    );
  }
}
