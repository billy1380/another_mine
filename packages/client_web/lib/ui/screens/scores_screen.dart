import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_web/ui/layout.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";

/// High scores. Not built yet, as in the Flutter client.
class ScoresScreen extends StatelessComponent {
  final bool useLayout;
  final String basePath;

  const ScoresScreen({super.key, this.useLayout = true, this.basePath = ""});

  @override
  Component build(BuildContext context) {
    if (!useLayout) return const ScoresView();

    return AppLayout(
      title: Strings.scores,
      basePath: basePath,
      child: const ScoresView(),
    );
  }
}

class ScoresView extends StatelessComponent {
  const ScoresView({super.key});

  @override
  Component build(BuildContext context) {
    return const div(
      classes: "text-center text-secondary p-4 p-md-5",
      attributes: {"style": "max-width: 640px; margin: 0 auto;"},
      [Component.text("Scores are not available yet.")],
    );
  }
}
