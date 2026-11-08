import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/pages/replay_page.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

/// An online score and the replay of its game, at `/score/<id>`.
class ScorePage extends StatefulWidget {
  static const String routePath = GameRoutes.score;

  /// The page from a route: the score is the one the list passed along, or is
  /// looked up by the id in the path.
  static GoRouterWidgetBuilder builder = (context, state) => ScorePage(
    key: ValueKey(state.pathParameters[GameRoutes.scoreParam]),
    id: int.tryParse(state.pathParameters[GameRoutes.scoreParam] ?? ""),
    score: state.extra as ScoreRow?,
  );

  /// Opens the replay of [score], or says it can't be played if its recording
  /// can't be read.
  static Future<void> open(BuildContext context, ScoreRow score) async {
    if (score.replay == null || score.id == null) {
      return ScoreDialogs.replayUnreadable();
    }

    final GoRouter? router = GoRouter.maybeOf(context);

    if (router != null) {
      await router.push(GameRoutes.scorePath(score.id!), extra: score);
    } else {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => ScorePage(score: score)));
    }
  }

  final int? id;
  final ScoreRow? score;

  const ScorePage({super.key, this.id, this.score});

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        Strings.replayTitle,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
    body: SafeArea(
      child: ScoreReplay(id: widget.id, score: widget.score),
    ),
  );
}

/// An online score, as given or looked up by [id], and the replay of its game.
/// Needs a [Material] above it.
class ScoreReplay extends StatefulWidget {
  final int? id;
  final ScoreRow? score;

  const ScoreReplay({super.key, this.id, this.score});

  @override
  State<ScoreReplay> createState() => _ScoreReplayState();
}

class _ScoreReplayState extends State<ScoreReplay> {
  late final Future<ScoreRow?> _score = widget.score != null
      ? Future.value(widget.score)
      : widget.id == null
      ? Future.value()
      : Provider.scoreKeeper.onlineScore(widget.id!);

  @override
  Widget build(BuildContext context) => FutureBuilder<ScoreRow?>(
    future: _score,
    builder: (context, snapshot) {
      final ScoreRow? score = snapshot.data;
      final Recording? recording = score?.replay;

      if (recording == null) {
        return Center(
          child: snapshot.connectionState != ConnectionState.done
              ? const CircularProgressIndicator()
              : Text(
                  snapshot.hasError
                      ? "${snapshot.error}"
                      : score == null
                      ? Strings.scoreNotFound
                      : Strings.replayUnreadableMessage,
                ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              Strings.replayOf(score!.name, score.detail),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(child: ReplayView(recording: recording)),
        ],
      );
    },
  );
}
