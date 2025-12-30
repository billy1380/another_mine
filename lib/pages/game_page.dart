import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/pages/parts/app_drawer.dart";
import "package:another_mine/widgets/game_action_bar.dart";
import "package:another_mine/widgets/mine_field.dart";
import "package:another_mine/routes.dart";
import "package:flutter/material.dart";
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
        return Scaffold(
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
              IconButton(
                tooltip: "Toggle Auto Solver",
                icon: Icon(state.autoSolverEnabled
                    ? Icons.smart_toy
                    : Icons.smart_toy_outlined),
                onPressed: state.isFinished
                    ? null
                    : () => BlocProvider.of<GameBloc>(context)
                        .add(const ToggleAutoSolver()),
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
                                  child: const Minefield(),
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
