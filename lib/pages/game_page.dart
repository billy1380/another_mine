import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/pages/parts/app_drawer.dart";
import "package:another_mine/widgets/game_action_bar.dart";
import "package:another_mine/widgets/mine_field.dart";
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

    return GamePage._(key: ValueKey(difficulty.description));
  };

  static String buildRoute(GameDifficulty difficulty) => routePath
      .replaceAll(":$widthParamName", difficulty.width.toString())
      .replaceAll(":$heightParamName", difficulty.height.toString())
      .replaceAll(":$minesParamName", difficulty.mines.toString());

  const GamePage._({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return Scaffold(
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
                onPressed: () => BlocProvider.of<GameBloc>(context)
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
}
