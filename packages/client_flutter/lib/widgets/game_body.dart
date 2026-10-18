import "dart:math";

import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_flutter/extensions/colour_ex.dart";
import "package:another_mine_flutter/widgets/game_action_bar.dart";
import "package:another_mine_flutter/widgets/mine_field.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// The playing area: the action bar (mines, new game, timer) above the
/// scrollable minefield.
///
/// Used by the stand alone game page and by the embeddable view, so it has to
/// work without a [Scaffold] or a router. Needs a [GameBloc] above it.
class GameBody extends StatefulWidget {
  const GameBody({super.key});

  @override
  State<GameBody> createState() => _GameBodyState();
}

class _GameBodyState extends State<GameBody> with WidgetsBindingObserver {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  final ValueNotifier<int?> _focusIndexNotifier = ValueNotifier<int?>(null);
  final FocusNode _focusNode = FocusNode();
  bool _pausedBySystem = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _focusIndexNotifier.dispose();
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseGame();
    } else if (state == AppLifecycleState.resumed) {
      _resumeGame();
    }
  }

  void _pauseGame() {
    final GameBloc bloc = BlocProvider.of<GameBloc>(context);
    if (bloc.state.lastActiveTime != null) {
      _pausedBySystem = true;
      bloc.add(const PauseGame());
    }
  }

  void _resumeGame() {
    if (_pausedBySystem) {
      final GameBloc bloc = BlocProvider.of<GameBloc>(context);
      _pausedBySystem = false;
      bloc.add(const ResumeGame());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: _onStateChanged,
      builder: (context, state) {
        return Focus(
          focusNode: _focusNode,
          onKeyEvent: (node, event) => _onKeyEvent(context, state, event),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionBar(state),
                Flexible(
                  child: _GameScrollable(
                    horizontalController: _horizontal,
                    verticalController: _vertical,
                    contentSize: state.gameSize.size,
                    child: Minefield(
                      focusIndexNotifier: _focusIndexNotifier,
                      isFocusMode: state.isFocusMode,
                      showProbabilities: state.showProbability,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onStateChanged(BuildContext context, GameState state) {
    if (state.autoSolverEnabled &&
        !state.autoSolverPaused &&
        state.lastInteractedIndex != null) {
      _scrollToIndex(
        state.lastInteractedIndex!,
        state.difficulty.width,
        state.gameSize.size,
      );
    }
  }

  KeyEventResult _onKeyEvent(
    BuildContext context,
    GameState state,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final bloc = context.read<GameBloc>();
    if (event.logicalKey == LogicalKeyboardKey.space &&
        !state.autoSolverEnabled) {
      bloc.add(const ToggleFocusMode());
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
      bloc.add(const ToggleProbabilities());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildActionBar(GameState state) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: state.gameSize.width),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: GameActionBar(),
        ),
      ),
    );
  }

  void _scrollToIndex(int index, int width, Size gameSize) {
    if (!_horizontal.hasClients || !_vertical.hasClients) return;

    final double mineDim = width > 0 ? gameSize.width / width : 40.0;
    final int row = index ~/ width;
    final int col = index % width;

    final double targetY = row * mineDim;
    final double targetX = col * mineDim;

    final double viewportHeight = _vertical.position.viewportDimension;
    final double viewportWidth = _horizontal.position.viewportDimension;

    final double scrollToY = (targetY - (viewportHeight / 2) + (mineDim / 2))
        .clamp(
          _vertical.position.minScrollExtent,
          _vertical.position.maxScrollExtent,
        );
    final double scrollToX = (targetX - (viewportWidth / 2) + (mineDim / 2))
        .clamp(
          _horizontal.position.minScrollExtent,
          _horizontal.position.maxScrollExtent,
        );

    _vertical.animateTo(
      scrollToY,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _horizontal.animateTo(
      scrollToX,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

class _GameScrollable extends StatelessWidget {
  final ScrollController horizontalController;
  final ScrollController verticalController;
  final Size contentSize;
  final Widget child;

  const _GameScrollable({
    required this.horizontalController,
    required this.verticalController,
    required this.contentSize,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final displaySize = Size(
          min(contentSize.width, constraints.maxWidth),
          min(contentSize.height, constraints.maxHeight),
        );

        return SizedBox.fromSize(
          size: displaySize,
          child: _buildScrollbar(
            controller: verticalController,
            depth: 0,
            child: _buildScrollbar(
              controller: horizontalController,
              depth: 1,
              child: SingleChildScrollView(
                controller: verticalController,
                child: SingleChildScrollView(
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox.fromSize(size: contentSize, child: child),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollbar({
    required ScrollController controller,
    required int depth,
    required Widget child,
  }) {
    return RawScrollbar(
      controller: controller,
      thumbVisibility: true,
      padding: EdgeInsets.zero,
      mainAxisMargin: 0,
      crossAxisMargin: 0,
      radius: const Radius.circular(8),
      notificationPredicate: (n) => n.depth == depth,
      child: child,
    );
  }
}
