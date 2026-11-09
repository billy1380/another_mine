import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_web/ui/layout.dart";
import "package:another_mine_web/ui/parts/small_picture.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";
import "package:jaspr_router/jaspr_router.dart";
import "package:mine_images/mine_images.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

/// High scores.
class ScoresScreen extends StatelessComponent {
  final bool useLayout;
  final String basePath;
  final ScoreCategory? initialCategory;
  final void Function(ScoreCategory category)? onCategoryChanged;

  const ScoresScreen({
    super.key,
    this.useLayout = true,
    this.basePath = "",
    this.initialCategory,
    this.onCategoryChanged,
  });

  @override
  Component build(BuildContext context) {
    final ScoresView view = ScoresView(
      basePath: basePath,
      initialCategory: initialCategory,
      onCategoryChanged: onCategoryChanged,
    );

    if (!useLayout) return view;

    return AppLayout(title: Strings.scores, basePath: basePath, child: view);
  }
}

class ScoresView extends StatefulComponent {
  /// Prefix of the app's paths when it is mounted under another path.
  final String basePath;

  /// Called with the id of an online score the player wants to replay; a host
  /// that has a page for it goes there. Without one, the app's own route
  /// under [basePath] is used.
  final void Function(int id)? onScoreSelected;

  /// The tab to start on; beginner if null or it has no tab.
  final ScoreCategory? initialCategory;

  /// Called with the tab the player moves to, so a host can keep it in its
  /// address.
  final void Function(ScoreCategory category)? onCategoryChanged;

  const ScoresView({
    super.key,
    this.basePath = "",
    this.onScoreSelected,
    this.initialCategory,
    this.onCategoryChanged,
  });

  @override
  State<ScoresView> createState() => _ScoresViewState();
}

class _ScoresViewState extends State<ScoresView> {
  late ScoreCategory _category;
  List<ScoreRow>? _scores;
  Object? _error;

  /// The online scores could not be read and the player gave up.
  bool _failed = false;

  /// The scores are read from a store that the game, in its own view, writes
  /// to as games are won; so what was loaded can be stale by the time it is
  /// looked at. The category is loaded again whenever it is picked.
  bool get _hasScores => ServiceDiscovery.instance.isRegistered<ScoreKeeper>();

  @override
  void initState() {
    super.initState();
    final ScoreCategory start =
        component.initialCategory ?? ScoreCategory.beginner;
    final List<ScoreCategory> shown = Provider.scoreKeeper.categories;
    _category = shown.contains(start) ? start : shown.first;
    _load();
  }

  Future<void> _load() async {
    if (!_hasScores) return;

    final ScoreCategory category = _category;

    try {
      final List<ScoreRow>? scores = await ScoreDialogs.loadRows(
        Provider.scoreKeeper,
        category,
      );

      if (category != _category) return;

      if (scores != null) {
        setState(() {
          _scores = scores;
          _error = null;
        });
      } else if (!Provider.scoreKeeper.showsOnline) {
        // switched to local: its tabs, and this one's local scores
        setState(() => _scores = null);
        await _load();
      } else {
        setState(() => _failed = true);
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

  Future<void> _watch(ScoreRow score) async {
    if (score.replay == null || score.id == null) {
      return ScoreDialogs.replayUnreadable();
    }

    if (component.onScoreSelected != null) {
      component.onScoreSelected!(score.id!);
    } else if (mounted) {
      Router.of(context)
          .push("${component.basePath}${GameRoutes.scorePath(score.id!)}");
    }
  }

  void _select(ScoreCategory category) {
    component.onCategoryChanged?.call(category);
    setState(() {
      _category = category;
      _scores = null;
      _error = null;
      _failed = false;
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
      attributes: const {"style": "max-width: 800px; margin: 0 auto;"},
      [
        // Bootstrap's own tabs, as the rest of the site has them, so they follow
        // the host page's theme. No overflow on the strip: it would clip the
        // selected tab's overlap of the strip's line, leaving a border at its base.
        ul(
          classes: "nav nav-tabs mb-3",
          attributes: const {"role": "tablist"},
          [
            for (final ScoreCategory category
                in Provider.scoreKeeper.categories)
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
    final List<ScoreRow>? scores = _scores;

    if (_failed) {
      return const div(classes: "text-secondary", [
        Component.text(Strings.scoresNotLoaded),
      ]);
    } else if (_error != null) {
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
      if (!Provider.scoreKeeper.showsOnline)
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

  Component _row(int place, ScoreRow score) {
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
            div(classes: "d-flex align-items-center gap-2", [
              div(classes: "text-truncate", [Component.text(score.name)]),
              if (score.service != null) smallPicture(score.service!),
            ]),
            div(classes: "d-flex align-items-center gap-2 small text-secondary", [
              if (score.flag != null)
                smallPicture(score.flag!)
              else if (score.country != null)
                Component.text("${score.country} ·"),
              div(
                classes: "text-truncate",
                // hovering shows the moment to the second
                attributes: {"title": formatFullTime(score.when)},
                [
                  Component.text(
                    "${score.detail} · ${formatDay(score.when)} ${formatClock(score.when)}",
                  ),
                ],
              ),
            ]),
          ],
        ),
        div(classes: "flex-shrink-0 fs-6 fw-medium", [
          Component.text("${score.seconds} s"),
        ]),
        if (score.recording != null)
          button(
            classes: "btn btn-sm btn-link text-secondary p-1",
            attributes: const {
              "type": "button",
              "title": Strings.replayTooltip,
              "aria-label": Strings.replayTooltip,
            },
            events: {"click": (e) => _watch(score)},
            [i(classes: "bi bi-play-circle", const [])],
          ),
        if (score.local != null)
          button(
            classes: "btn btn-sm btn-link text-secondary p-1",
            attributes: const {
              "type": "button",
              "title": Strings.deleteScoreTooltip,
              "aria-label": Strings.deleteScoreTooltip,
            },
            events: {"click": (e) => _delete(score.local!)},
            [i(classes: "bi bi-trash", const [])],
          ),
      ],
    );
  }
}
