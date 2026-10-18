import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/pages/parts/app_drawer.dart";
import "package:another_mine/widgets/game_body.dart";
import "package:another_mine/widgets/game_tools_menu.dart";
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

class _GamePageState extends State<GamePage> with RouteAware {
  bool _pausedBySystem = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() => _pauseGame();

  @override
  void didPopNext() => _resumeGame();

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
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return Scaffold(
          onDrawerChanged: _onDrawerChanged,
          drawer: const AppDrawer(),
          appBar: _buildAppBar(context, state),
          body: const GameBody(),
          floatingActionButton: _buildFAB(context, state),
        );
      },
    );
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
      actions: const [GameToolsMenu()],
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
}
