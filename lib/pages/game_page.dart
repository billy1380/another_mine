import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/pages/parts/app_drawer.dart";
import "package:another_mine/widgets/game_action_bar.dart";
import "package:another_mine/widgets/mine_field.dart";
import "package:another_mine/routes.dart";
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

    BlocProvider.of<GameBloc>(context).add(NewGame(difficulty: difficulty));

    BlocProvider.of<GameBloc>(context).add(NewGame(difficulty: difficulty));

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
    super.dispose();
  }

  @override
  void didPushNext() {
    _pauseGame();
  }

  @override
  void didPopNext() {
    _resumeGame();
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
    final GameState state = bloc.state;

    if (state.lastActiveTime != null) {
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
      listener: (context, state) {
        if (state.autoSolverEnabled &&
            !state.autoSolverPaused &&
            state.lastInteractedIndex != null) {
          _scrollToIndex(state.lastInteractedIndex!, state.difficulty.width,
              state.gameSize);
        }
      },
      builder: (context, state) {
        if (state.autoSolverEnabled && state.isFocusMode) {
          // Auto-disable focus mode if auto solver is enabled
          // But since state is immutable and handled by bloc, we should dispatch event?
          // Or just trust the bloc to handle valid states?
          // The previous logic used addPostFrameCallback to setState.
          // Ideally GameBloc should prevent enabling focus mode if auto solver is on,
          // OR auto solver turning on should disable focus mode.
          // For now, let's just dispatch the toggle event if needed, but beware of loops.
          // Actually, better to handle this logic in the Bloc listeners or Bloc logic itself.
          // Let's defer this strictly to the Bloc.
        }

        return Focus(
          focusNode: _focusNode,
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.space &&
                event is KeyDownEvent &&
                !state.autoSolverEnabled) {
              BlocProvider.of<GameBloc>(context).add(const ToggleFocusMode());
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyP &&
                event is KeyDownEvent) {
              BlocProvider.of<GameBloc>(context)
                  .add(const ToggleProbabilities());
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Scaffold(
            onDrawerChanged: (isOpened) {
              if (isOpened) {
                _pauseGame();
              } else {
                _resumeGame();
              }
            },
            drawer: const AppDrawer(),
            appBar: AppBar(
              title: Text(
                  "${StringUtils.upperCaseFirstLetter(state.difficulty.name)} - ${StringUtils.upperCaseFirstLetter(state.difficulty.description)}",
                  style: Theme.of(context).textTheme.bodyLarge),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  tooltip: "Game Tools",
                  onSelected: (value) {
                    final bloc = BlocProvider.of<GameBloc>(context);
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
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                        value: "solver",
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                state.autoSolverEnabled
                                    ? Icons.smart_toy
                                    : Icons.smart_toy_outlined,
                                color: Colors.black),
                            const SizedBox(width: 8),
                            const Text("Auto Solver"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "probability",
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                state.showProbability
                                    ? Icons.percent
                                    : Icons.percent_outlined,
                                color: Colors.black),
                            const SizedBox(width: 8),
                            const Text("Probabilities"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "focus",
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                state.isFocusMode
                                    ? Icons.center_focus_strong
                                    : Icons.center_focus_strong_outlined,
                                color: Colors.black),
                            const SizedBox(width: 8),
                            const Text("Focus Mode"),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: state.gameSize.width,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: GameActionBar(),
                    ),
                  ),
                ),
                Flexible(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Scrollbar(
                        controller: _horizontal,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontal,
                          scrollDirection: Axis.horizontal,
                          child: Scrollbar(
                            controller: _vertical,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _vertical,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: state.gameSize.width,
                                    height: state.gameSize.height,
                                    child: Minefield(
                                      focusIndexNotifier: _focusIndexNotifier,
                                      isFocusMode: state.isFocusMode,
                                      showProbabilities: state.showProbability,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: state.autoSolverEnabled
                ? FloatingActionButton(
                    onPressed: () {
                      BlocProvider.of<GameBloc>(context).add(
                          state.autoSolverPaused
                              ? const ResumeAutoSolver()
                              : const PauseAutoSolver());
                    },
                    child: state.autoSolverPaused
                        ? const Icon(Icons.play_arrow)
                        : const Icon(Icons.pause),
                  )
                : null,
          ),
        );
      },
    );
  }

  void _scrollToIndex(int index, int width, Size gameSize) {
    if (!_horizontal.hasClients || !_vertical.hasClients) return;

    // mineDim is 40.0, derived from gameSize / count or constant.
    // game_bloc defines it as constant. Since we don't have it imported,
    // we can calculate it or assume it. Since GameState stores gameSize:
    // width * mineDim = gameSize.width
    double mineDim = 40.0;
    if (width > 0) {
      mineDim = gameSize.width / width;
    }

    final int row = index ~/ width;
    final int col = index % width;

    final double targetY = row * mineDim;
    final double targetX = col * mineDim;

    // Viewport dimensions
    final double viewportHeight = _vertical.position.viewportDimension;
    final double viewportWidth = _horizontal.position.viewportDimension;

    // Center the target
    double scrollToY = targetY - (viewportHeight / 2) + (mineDim / 2);
    double scrollToX = targetX - (viewportWidth / 2) + (mineDim / 2);

    // Clamp
    scrollToY = scrollToY.clamp(
        _vertical.position.minScrollExtent, _vertical.position.maxScrollExtent);
    scrollToX = scrollToX.clamp(_horizontal.position.minScrollExtent,
        _horizontal.position.maxScrollExtent);

    // Animate
    _vertical.animateTo(scrollToY,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _horizontal.animateTo(scrollToX,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }
}
