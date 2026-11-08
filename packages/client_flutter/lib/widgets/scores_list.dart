import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/assets.dart";
import "package:flutter/material.dart";
import "package:mine_images/mine_images.dart";

/// The local high scores, a tab for each category.
///
/// Brings its own [DefaultTabController] and needs only a [Material] above it,
/// which both the game's page and the embeddable view have, so it works with or
/// without a router, scaffold or drawer around it. The tab starting selected is
/// the category of the game last played.
class ScoresList extends StatelessWidget {
  const ScoresList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ScoreCategory> categories = ScoreCategory.values;
    final ScoreCategory current = ScoreCategory.forDifficulty(
      Provider.pref.difficulty,
    );

    return DefaultTabController(
      length: categories.length,
      initialIndex: categories.indexOf(current),
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
                  _CategoryScores(category: category),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The best scores of one category, read when its tab is first shown and kept
/// while the tabs are switched.
class _CategoryScores extends StatefulWidget {
  final ScoreCategory category;

  const _CategoryScores({required this.category});

  @override
  State<_CategoryScores> createState() => _CategoryScoresState();
}

class _CategoryScoresState extends State<_CategoryScores>
    with AutomaticKeepAliveClientMixin {
  late Future<List<LocalScore>> _scores = Provider.scoreKeeper.top(
    widget.category,
  );

  void _reload() => setState(() {
    _scores = Provider.scoreKeeper.top(widget.category);
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

    return FutureBuilder<List<LocalScore>>(
      future: _scores,
      builder: (context, snapshot) {
        final List<LocalScore>? scores = snapshot.data;

        if (scores == null) {
          return snapshot.hasError
              ? Center(child: Text("${snapshot.error}"))
              : const Center(child: CircularProgressIndicator());
        } else if (scores.isEmpty) {
          return const Center(child: Text(Strings.noScoresYet));
        }

        return ListView.builder(
          // one more than the scores: the button to delete them all
          itemCount: scores.length + 1,
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
                  onDelete: () => _delete(scores[index]),
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
  final LocalScore score;
  final VoidCallback onDelete;

  const _ScoreTile({
    required this.place,
    required this.score,
    required this.onDelete,
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
      title: Text(score.name),
      // hovering, or pressing and holding, shows the moment to the second
      subtitle: Tooltip(
        message: formatFullTime(score.when),
        child: Text(
          "${score.board} · ${localizations.formatMediumDate(score.when)} ${formatClock(score.when)}",
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${score.seconds} s",
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
