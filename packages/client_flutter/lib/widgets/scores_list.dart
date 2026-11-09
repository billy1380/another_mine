import "dart:math";

import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/assets.dart";
import "package:another_mine_flutter/pages/score_page.dart";
import "package:another_mine_flutter/widgets/small_picture.dart";
import "package:flutter/material.dart";
import "package:mine_images/mine_images.dart";

/// The high scores, a tab for each category: this device's, or the online ones
/// when online scores are on (Custom Easy is local only, so it has no tab then).
///
/// Brings its own [DefaultTabController] and needs only a [Material] above it,
/// which both the game's page and the embeddable view have, so it works with or
/// without a router, scaffold or drawer around it. The tab starting selected is
/// [initialCategory], beginner if there is none or it has no tab.
class ScoresList extends StatefulWidget {
  /// Called with the id of an online score the player wants to replay; a host
  /// that has a page for it goes there. Without one the game's own router, or
  /// its own navigator, opens it.
  final ValueChanged<int>? onOpenScore;

  /// The tab to start on.
  final ScoreCategory? initialCategory;

  /// Called with the category of the tab the player moved to, so a host can
  /// keep it in its address.
  final ValueChanged<ScoreCategory>? onCategoryChanged;

  const ScoresList({
    super.key,
    this.onOpenScore,
    this.initialCategory,
    this.onCategoryChanged,
  });

  @override
  State<ScoresList> createState() => _ScoresListState();
}

class _ScoresListState extends State<ScoresList> {
  @override
  Widget build(BuildContext context) {
    final List<ScoreCategory> categories = Provider.scoreKeeper.categories;

    return DefaultTabController(
      length: categories.length,
      initialIndex: max(
        0,
        categories.indexOf(widget.initialCategory ?? ScoreCategory.beginner),
      ),
      child: _TabWatch(
        onChanged: (index) => widget.onCategoryChanged?.call(categories[index]),
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final ScoreCategory category in categories)
                  Tab(text: category.label),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final ScoreCategory category in categories)
                    _CategoryScores(
                      key: ValueKey(
                        "${category.localId}-${Provider.scoreKeeper.showsOnline}",
                      ),
                      category: category,
                      onOpenScore: widget.onOpenScore,
                      onSwitchedToLocal: () => setState(() {}),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tells [onChanged] the index of the tab the player has moved to, once it has
/// settled there (for a tap, after the animation; for a swipe, when it ends).
class _TabWatch extends StatefulWidget {
  final ValueChanged<int> onChanged;
  final Widget child;

  const _TabWatch({required this.onChanged, required this.child});

  @override
  State<_TabWatch> createState() => _TabWatchState();
}

class _TabWatchState extends State<_TabWatch> {
  TabController? _controller;
  int? _last;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final TabController controller = DefaultTabController.of(context);

    if (controller != _controller) {
      _controller?.removeListener(_changed);
      _controller = controller..addListener(_changed);
      _last = controller.index;
    }
  }

  void _changed() {
    final TabController controller = _controller!;

    if (!controller.indexIsChanging && controller.index != _last) {
      _last = controller.index;
      widget.onChanged(controller.index);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The best scores of one category, read when its tab is first shown and kept
/// while the tabs are switched.
class _CategoryScores extends StatefulWidget {
  final ScoreCategory category;

  /// Called once the player has chosen to switch to local scores, so the tabs
  /// are drawn again.
  final VoidCallback onSwitchedToLocal;
  final ValueChanged<int>? onOpenScore;

  const _CategoryScores({
    super.key,
    required this.category,
    required this.onOpenScore,
    required this.onSwitchedToLocal,
  });

  @override
  State<_CategoryScores> createState() => _CategoryScoresState();
}

class _CategoryScoresState extends State<_CategoryScores>
    with AutomaticKeepAliveClientMixin {
  bool get _online => Provider.scoreKeeper.showsOnline;

  late Future<List<ScoreRow>?> _scores = _load();

  /// Null if the online scores could not be read and the player gave up or
  /// switched to local.
  Future<List<ScoreRow>?> _load() async {
    final List<ScoreRow>? rows = await ScoreDialogs.loadRows(
      Provider.scoreKeeper,
      widget.category,
    );

    if (rows == null && !_online && mounted) widget.onSwitchedToLocal();

    return rows;
  }

  void _reload() => setState(() {
    _scores = _load();
  });

  Future<void> _delete(LocalScore score) async {
    if (!await ScoreDialogs.confirmDeleteScore(score)) return;

    await Provider.scoreKeeper.remove(score);
    if (mounted) _reload();
  }

  Future<void> _deleteAll() async {
    if (!await ScoreDialogs.confirmDeleteAll(widget.category.label)) return;

    await Provider.scoreKeeper.clearCategory(widget.category);
    if (mounted) _reload();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<List<ScoreRow>?>(
      future: _scores,
      builder: (context, snapshot) {
        final List<ScoreRow>? scores = snapshot.data;

        if (scores == null) {
          return snapshot.connectionState == ConnectionState.done
              ? Center(
                  child: snapshot.hasError
                      ? Text("${snapshot.error}")
                      : const Text(Strings.scoresNotLoaded),
                )
              : const Center(child: CircularProgressIndicator());
        } else if (scores.isEmpty) {
          return const Center(child: Text(Strings.noScoresYet));
        }

        return ListView.builder(
          // one more than the local scores: the button to delete them all
          itemCount: scores.length + (_online ? 0 : 1),
          itemBuilder: (context, index) => index == scores.length
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _deleteAll,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: Text(Strings.deleteAll(widget.category.label)),
                    ),
                  ),
                )
              : _ScoreTile(
                  place: index + 1,
                  score: scores[index],
                  onDelete: _online
                      ? null
                      : () => _delete(scores[index].local!),
                  onReplay: scores[index].recording == null
                      ? null
                      : () =>
                            widget.onOpenScore != null &&
                                scores[index].replay != null &&
                                scores[index].id != null
                            ? widget.onOpenScore!(scores[index].id!)
                            : ScorePage.open(context, scores[index]),
                ),
        );
      },
    );
  }
}

/// The gold, silver or bronze medal for the first three places.
MineImage? medalFor(int place) => switch (place) {
  1 => MineImage.medal1,
  2 => MineImage.medal2,
  3 => MineImage.medal3,
  _ => null,
};

class _ScoreTile extends StatelessWidget {
  final int place;
  final ScoreRow score;
  final VoidCallback? onDelete;
  final VoidCallback? onReplay;

  const _ScoreTile({
    required this.place,
    required this.score,
    required this.onDelete,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final MineImage? medal = medalFor(place);

    return ListTile(
      leading: SizedBox(
        width: 40,
        height: 40,
        child: medal == null
            ? Center(
                child: Text(
                  "$place",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            : AnotherMineAssets.image(medal, height: 40),
      ),
      title: Row(
        children: [
          Flexible(child: Text(score.name)),
          if (score.service != null) ...[
            const SizedBox(width: 8),
            SmallPicture(score.service!),
          ],
        ],
      ),
      // hovering, or pressing and holding, shows the moment to the second
      subtitle: Row(
        children: [
          if (score.flag != null) ...[
            SmallPicture(score.flag!),
            const SizedBox(width: 8),
          ] else if (score.country != null)
            Text("${score.country} · "),
          Expanded(
            child: Tooltip(
              message: formatFullTime(score.when),
              child: Text(
                "${score.detail} · ${localizations.formatMediumDate(score.when)} ${formatClock(score.when)}",
              ),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${score.seconds} s",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (onReplay != null)
            IconButton(
              tooltip: Strings.replayTooltip,
              icon: const Icon(Icons.play_circle_outline),
              onPressed: onReplay,
            ),
          if (onDelete != null)
            IconButton(
              tooltip: Strings.deleteScoreTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
