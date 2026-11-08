import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_web/ui/layout.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";
import "package:mine_images/mine_images.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

/// High scores.
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

class ScoresView extends StatefulComponent {
  const ScoresView({super.key});

  @override
  State<ScoresView> createState() => _ScoresViewState();
}

class _ScoresViewState extends State<ScoresView> {
  late ScoreCategory _category;
  List<LocalScore>? _scores;
  Object? _error;

  /// The scores are read from a store that the game, in its own view, writes
  /// to as games are won; so what was loaded can be stale by the time it is
  /// looked at. The category is loaded again whenever it is picked.
  bool get _hasScores => ServiceDiscovery.instance.isRegistered<ScoreKeeper>();

  @override
  void initState() {
    super.initState();
    _category = ScoreCategory.forDifficulty(Provider.pref.difficulty);
    _load();
  }

  Future<void> _load() async {
    if (!_hasScores) return;

    final ScoreCategory category = _category;

    try {
      final List<LocalScore> scores = await Provider.scoreKeeper.top(category);

      if (category == _category) {
        setState(() {
          _scores = scores;
          _error = null;
        });
      }
    } catch (e) {
      if (category == _category) setState(() => _error = e);
    }
  }

  /// Asks whether to delete [score], and deletes it if the answer is yes.
  Future<void> _delete(LocalScore score) async {
    if (!await ScoreDialogs.confirmDeleteScore(score)) return;

    await Provider.scoreKeeper.remove(score);
    await _load();
  }

  /// Asks whether to delete every score of the category being shown, and does
  /// if the answer is yes.
  Future<void> _deleteAll() async {
    final ScoreCategory category = _category;
    if (!await ScoreDialogs.confirmDeleteAll(category.label)) return;

    await Provider.scoreKeeper.clearCategory(category);
    await _load();
  }

  void _select(ScoreCategory category) {
    setState(() {
      _category = category;
      _scores = null;
      _error = null;
    });
    _load();
  }

  @override
  Component build(BuildContext context) {
    if (!_hasScores) {
      return const div(classes: "text-center text-secondary p-4 p-md-5", [
        Component.text("Scores are not available here."),
      ]);
    }

    return div(
      classes: "p-3",
      attributes: const {"style": "max-width: 640px; margin: 0 auto;"},
      [
        // Bootstrap's own tabs, as the rest of the site has them, so they follow
        // the host page's theme. No overflow on the strip: it would clip the
        // selected tab's overlap of the strip's line, leaving a border at its base.
        ul(
          classes: "nav nav-tabs mb-3",
          attributes: const {"role": "tablist"},
          [
            for (final ScoreCategory category in ScoreCategory.values)
              li(
                classes: "nav-item",
                attributes: const {"role": "presentation"},
                [
                  button(
                    classes:
                        "nav-link${category == _category ? " active" : ""}",
                    attributes: {
                      "type": "button",
                      "role": "tab",
                      "aria-selected": "${category == _category}",
                    },
                    events: {"click": (e) => _select(category)},
                    [Component.text(category.label)],
                  ),
                ],
              ),
          ],
        ),
        div(attributes: const {"role": "tabpanel"}, [_body()]),
      ],
    );
  }

  /// The gold, silver or bronze medal for the first three places, else the
  /// number.
  Component _place(int place) {
    final MineImage? medal = switch (place) {
      1 => MineImage.medal1,
      2 => MineImage.medal2,
      3 => MineImage.medal3,
      _ => null,
    };

    if (medal == null) {
      return span(classes: "fs-6 fw-medium", [Component.text("$place")]);
    }

    return img(
      src: "/assets/${medal.webPath}",
      alt: "Place $place",
      attributes: const {"width": "40", "height": "40"},
    );
  }

  Component _body() {
    final List<LocalScore>? scores = _scores;

    if (_error != null) {
      return div(classes: "text-danger", [Component.text("$_error")]);
    } else if (scores == null) {
      return const div(classes: "text-secondary", [
        Component.text("Loading..."),
      ]);
    } else if (scores.isEmpty) {
      return const div(classes: "text-secondary", [
        Component.text(Strings.noScoresYet),
      ]);
    }

    // rows like the Flutter client's list: the place or medal, the name above
    // the board and when, and the time on the right
    return Component.fragment([
      div(classes: "list-group list-group-flush", [
        for (int i = 0; i < scores.length; i++) _row(i + 1, scores[i]),
      ]),
      div(classes: "d-flex justify-content-end mt-2", [
        button(
          classes: "btn btn-sm btn-outline-danger",
          attributes: const {"type": "button"},
          events: {"click": (e) => _deleteAll()},
          [
            i(classes: "bi bi-trash me-1", const []),
            Component.text(Strings.deleteAll(_category.label)),
          ],
        ),
      ]),
    ]);
  }

  Component _row(int place, LocalScore score) {
    return div(
      classes:
          "list-group-item bg-transparent d-flex align-items-center gap-3 px-2",
      [
        div(
          classes:
              "flex-shrink-0 d-flex align-items-center justify-content-center",
          attributes: const {"style": "width: 40px; height: 40px;"},
          [_place(place)],
        ),
        div(
          classes: "flex-grow-1",
          attributes: const {"style": "min-width: 0;"},
          [
            div(classes: "text-truncate", [Component.text(score.name)]),
            div(
              classes: "small text-secondary text-truncate",
              // hovering shows the moment to the second
              attributes: {"title": formatFullTime(score.when)},
              [
                Component.text(
                  "${score.board} · ${formatDay(score.when)} ${formatClock(score.when)}",
                ),
              ],
            ),
          ],
        ),
        div(classes: "flex-shrink-0 fs-6 fw-medium", [
          Component.text("${score.seconds} s"),
        ]),
        button(
          classes: "btn btn-sm btn-link text-secondary p-1",
          attributes: const {
            "type": "button",
            "title": Strings.deleteScoreTooltip,
            "aria-label": Strings.deleteScoreTooltip,
          },
          events: {"click": (e) => _delete(score)},
          [i(classes: "bi bi-trash", const [])],
        ),
      ],
    );
  }
}
