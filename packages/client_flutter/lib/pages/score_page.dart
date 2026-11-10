import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/pages/replay_page.dart";
import "package:another_mine_flutter/widgets/small_picture.dart";
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
            child: _Player(score: score!),
          ),
          Expanded(child: ReplayView(recording: recording)),
        ],
      );
    },
  );
}

/// `name · board`, then `[logo] service · [flag] country` under it.
class _Player extends StatelessWidget {
  final ScoreRow score;

  const _Player({required this.score});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        Strings.replayOf(score.name, score.detail),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          if (score.service != null) SmallPicture(score.service!, height: 20),
          if (score.serviceName != null) Text("${score.serviceName} ·"),
          if (score.flag != null) SmallPicture(score.flag!),
          if (score.country != null) Text(score.country!),
        ],
      ),
    ],
  );
}
