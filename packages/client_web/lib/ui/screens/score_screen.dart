import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/another_mine_flutter.dart"
    show EmbeddedReplay;
import "package:another_mine_web/ui/layout.dart";
import "package:another_mine_web/ui/parts/small_picture.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";
import "package:jaspr_flutter_embed/jaspr_flutter_embed.dart";

/// An online score and the replay of its game, at `/score/<id>`.
class ScoreScreen extends StatelessComponent {
  final int? id;
  final bool useLayout;
  final String basePath;

  const ScoreScreen({
    super.key,
    required this.id,
    this.useLayout = true,
    this.basePath = "",
  });

  @override
  Component build(BuildContext context) {
    final Component view = ScoreView(id: id);

    if (!useLayout) return view;

    return AppLayout(
      title: Strings.replayTitle,
      basePath: basePath,
      child: view,
    );
  }
}

class ScoreView extends StatefulComponent {
  final int? id;

  const ScoreView({super.key, required this.id});

  @override
  State<ScoreView> createState() => _ScoreViewState();
}

class _ScoreViewState extends State<ScoreView> {
  ScoreRow? _score;
  Object? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final int? id = component.id;

    try {
      final ScoreRow? score = id == null
          ? null
          : await Provider.scoreKeeper.onlineScore(id);

      if (mounted) {
        setState(() {
          _score = score;
          _done = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _done = true;
        });
      }
    }
  }

  @override
  Component build(BuildContext context) {
    final ScoreRow? score = _score;
    final Recording? recording = score?.replay;

    if (!_done) {
      return const div(classes: "text-secondary", [
        Component.text("Loading..."),
      ]);
    } else if (_error != null) {
      return div(classes: "text-danger", [Component.text("$_error")]);
    } else if (score == null || recording == null) {
      return div(classes: "text-secondary", [
        Component.text(
          score == null
              ? Strings.scoreNotFound
              : Strings.replayUnreadableMessage,
        ),
      ]);
    }

    return div(classes: "d-flex flex-column gap-2", [
      div(classes: "text-center", [
        div([Component.text(Strings.replayOf(score.name, score.detail))]),
        div(classes: "d-flex justify-content-center align-items-center gap-2", [
          if (score.service != null) smallPicture(score.service!, height: 20),
          if (score.serviceName != null)
            Component.text("${score.serviceName} ·"),
          if (score.flag != null) smallPicture(score.flag!),
          if (score.country != null) Component.text(score.country!),
        ]),
      ]),
      div(
        attributes: const {"style": "height: 70vh; min-height: 0;"},
        events: {"contextmenu": (e) => e.preventDefault()},
        [
          FlutterEmbedView(
            classes: "w-100 h-100",
            widget: EmbeddedReplay(recording: recording),
          ),
        ],
      ),
    ]);
  }
}
