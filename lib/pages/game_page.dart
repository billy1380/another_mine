import "dart:math";
import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/pages/parts/app_drawer.dart";
import "package:another_mine/widgets/game_action_bar.dart";
import "package:another_mine/widgets/mine_field.dart";
import "package:another_mine/routes.dart";
import "package:another_mine/strings.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:willshex/willshex.dart";

class GamePage extends StatefulWidget {
  static const widthParamName = "width";
  static const widthParam = ":$widthParamName";
  static const heightParamName = "height";
  static const heightParam = ":$heightParamName";
  static const minesParamName = "mines";
  static const minesParam = ":$minesParamName";

  static const routePath = "/game/$widthParam/$heightParam/$minesParam";

  static GoRouterWidgetBuilder builder = (context, state) {
    final String? widthParamValue = state.pathParameters[widthParamName];
    final String? heightParamValue = state.pathParameters[heightParamName];
    final String? minesParamValue = state.pathParameters[minesParamName];

    final int width = widthParamValue == null
        ? GameDifficulty.beginner.width
        : int.tryParse(widthParamValue) ?? GameDifficulty.beginner.width;
    final int height = heightParamValue == null
        ? GameDifficulty.beginner.height
        : int.tryParse(heightParamValue) ?? GameDifficulty.beginner.height;
    final int mines = minesParamValue == null
        ? GameDifficulty.beginner.mines
        : int.tryParse(minesParamValue) ?? GameDifficulty.beginner.mines;

    GameDifficulty difficulty = GameDifficulty.values.firstWhere(
      (e) => e.sameAs(width, height, mines),
      orElse: () =>
          GameDifficulty.custom(width: width, height: height, mines: mines),
    );

    final GameBloc bloc = BlocProvider.of<GameBloc>(context);
    if (bloc.state.difficulty != difficulty) {
      bloc.add(NewGame(difficulty: difficulty));
    }

    return GamePage(key: ValueKey(difficulty.description));
  };

  static String buildRoute(GameDifficulty difficulty) => routePath
      .replaceAll(":$widthParamName", difficulty.width.toString())
      .replaceAll(":$heightParamName", difficulty.height.toString())
      .replaceAll(":$minesParamName", difficulty.mines.toString());

  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with RouteAware, WidgetsBindingObserver {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  bool _pausedBySystem = false;
  ValueNotifier<int?>? _focusIndexNotifier;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusIndexNotifier = ValueNotifier<int?>(null);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _focusIndexNotifier?.dispose();
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  void didPushNext() => _pauseGame();

  @override
  void didPopNext() => _resumeGame();

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
          child: Scaffold(
            onDrawerChanged: _onDrawerChanged,
            drawer: const AppDrawer(),
            appBar: _buildAppBar(context, state),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionBar(state),
                  Flexible(
                    child: _GameScrollable(
                      horizontalController: _horizontal,
                      verticalController: _vertical,
                      contentSize: state.gameSize,
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
            floatingActionButton: _buildFAB(context, state),
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
          state.lastInteractedIndex!, state.difficulty.width, state.gameSize);
    }
  }

  KeyEventResult _onKeyEvent(
      BuildContext context, GameState state, KeyEvent event) {
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

  void _onDrawerChanged(bool isOpened) {
    if (isOpened) {
      _pauseGame();
    } else {
      _resumeGame();
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, GameState state) {
    return AppBar(
      title: Text(
          "${StringUtils.upperCaseFirstLetter(state.difficulty.name)} - ${StringUtils.upperCaseFirstLetter(state.difficulty.description)}",
          style: Theme.of(context).textTheme.bodyLarge),
      actions: [_buildPopupMenu(context, state)],
    );
  }

  Widget _buildPopupMenu(BuildContext context, GameState state) {
    final bool gameWon = state.status == GameStateType.won;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz),
      tooltip: Strings.gameToolsTooltip,
      onSelected: (value) {
        final bloc = context.read<GameBloc>();
        switch (value) {
          case "solver":
            bloc.add(const ToggleAutoSolver());
            break;
          case "probability":
            bloc.add(const ToggleProbabilities());
            break;
          case "focus":
            bloc.add(const ToggleFocusMode());
            break;
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem(
            "solver",
            state.autoSolverEnabled
                ? Icons.smart_toy
                : Icons.smart_toy_outlined,
            Strings.autoSolver,
            gameWon),
        _buildPopupItem(
            "probability",
            state.showProbability ? Icons.percent : Icons.percent_outlined,
            Strings.probabilities,
            gameWon),
        _buildPopupItem(
            "focus",
            state.isFocusMode
                ? Icons.center_focus_strong
                : Icons.center_focus_strong_outlined,
            Strings.focusMode,
            gameWon),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      String value, IconData icon, String label, bool isDisabled) {
    return PopupMenuItem(
      value: value,
      enabled: !isDisabled,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isDisabled ? Colors.grey : Colors.black),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: isDisabled ? Colors.grey : Colors.black)),
        ],
      ),
    );
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

  Widget? _buildFAB(BuildContext context, GameState state) {
    if (!state.autoSolverEnabled) return null;
    return FloatingActionButton(
      onPressed: () {
        context.read<GameBloc>().add(state.autoSolverPaused
            ? const ResumeAutoSolver()
            : const PauseAutoSolver());
      },
      child: Icon(state.autoSolverPaused ? Icons.play_arrow : Icons.pause),
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
        .clamp(_vertical.position.minScrollExtent,
            _vertical.position.maxScrollExtent);
    final double scrollToX = (targetX - (viewportWidth / 2) + (mineDim / 2))
        .clamp(_horizontal.position.minScrollExtent,
            _horizontal.position.maxScrollExtent);

    _vertical.animateTo(scrollToY,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _horizontal.animateTo(scrollToX,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                  child: SizedBox.fromSize(
                    size: contentSize,
                    child: child,
                  ),
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