import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/extensions/colour_ex.dart";
import "package:another_mine_flutter/widgets/digits.dart";
import "package:another_mine_flutter/widgets/game_body.dart";
import "package:another_mine_flutter/widgets/mine_field.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// The replay itself: the minefield played back, what the player had on, the
/// timeline and the speed. Needs a [Material] above it.
class ReplayView extends StatefulWidget {
  final Recording recording;

  const ReplayView({super.key, required this.recording});

  @override
  State<ReplayView> createState() => _ReplayViewState();
}

class _ReplayViewState extends State<ReplayView> {
  late final ReplayCubit _replay = ReplayCubit(widget.recording)..start();
  final ValueNotifier<int?> _focusIndex = ValueNotifier<int?>(null);
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();

  @override
  void dispose() {
    _replay.close();
    _focusIndex.dispose();
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<ReplayCubit>.value(
    value: _replay,
    child: BlocProvider<GameBloc>.value(
      value: _replay.bloc,
      child: Column(
        children: [
          const _AsWideAsBoard(child: _Bar()),
          Expanded(
            child: Center(
              child: BlocConsumer<GameBloc, GameState>(
                listener: (context, state) => _focusIndex.value =
                    state.isFocusMode ? state.lastInteractedIndex : null,
                builder: (context, state) => GameScrollable(
                  horizontalController: _horizontal,
                  verticalController: _vertical,
                  contentSize: state.gameSize.size,
                  // watching only: no taps, no hover
                  child: IgnorePointer(
                    child: Minefield(
                      focusIndexNotifier: _focusIndex,
                      isFocusMode: state.isFocusMode,
                      showProbabilities: state.showProbability,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const _AsWideAsBoard(child: _Controls()),
        ],
      ),
    ),
  );
}

/// [child], no wider than the minefield, as the game's own bar is.
class _AsWideAsBoard extends StatelessWidget {
  final Widget child;

  const _AsWideAsBoard({required this.child});

  @override
  Widget build(BuildContext context) => BlocBuilder<GameBloc, GameState>(
    buildWhen: (a, b) => a.gameSize != b.gameSize,
    builder: (context, state) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: state.gameSize.width),
        child: child,
      ),
    ),
  );
}

/// The mines left and the time played.
class _Bar extends StatelessWidget {
  const _Bar();

  @override
  Widget build(BuildContext context) => BlocBuilder<GameBloc, GameState>(
    builder: (context, game) => BlocBuilder<ReplayCubit, ReplayState>(
      builder: (context, replay) => Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Digits(
              name: "Mines",
              value: game.minesRemaining,
              backgroundColor: game.colour.color,
            ),
            const Spacer(),
            Digits(
              name: "Time",
              value: replay.position ~/ 1000,
              digits: 3,
              backgroundColor: game.colour.color,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Play, pause and play again, the timeline and the speed.
class _Controls extends StatefulWidget {
  const _Controls();

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  // while the timeline is being dragged, where it is
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final ReplayCubit cubit = context.read<ReplayCubit>();

    return BlocBuilder<ReplayCubit, ReplayState>(
      builder: (context, replay) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: replay.finished
                      ? Strings.replayAgain
                      : replay.playing
                      ? Strings.replayPause
                      : Strings.replayPlay,
                  icon: Icon(
                    replay.finished
                        ? Icons.replay
                        : replay.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  onPressed: replay.finished
                      ? cubit.restart
                      : replay.playing
                      ? cubit.pause
                      : cubit.play,
                ),
                Expanded(
                  child: Slider(
                    value: (_drag ?? replay.position.toDouble()).clamp(
                      0,
                      replay.total.toDouble(),
                    ),
                    max: replay.total == 0 ? 1 : replay.total.toDouble(),
                    onChanged: (v) => setState(() => _drag = v),
                    onChangeEnd: (v) {
                      setState(() => _drag = null);
                      cubit.seek(v.round());
                    },
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(Strings.replaySpeed),
                for (final double speed in ReplayCubit.speeds)
                  ChoiceChip(
                    label: Text(
                      "${speed == speed.roundToDouble() ? speed.round() : speed}x",
                    ),
                    selected: replay.speed == speed,
                    onSelected: (_) => cubit.setSpeed(speed),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
