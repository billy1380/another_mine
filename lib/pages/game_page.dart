import 'package:another_mine/bloc/game/game_bloc.dart';
import 'package:another_mine/model/game_difficulty_type.dart';
import 'package:another_mine/pages/parts/app_drawer.dart';
import 'package:another_mine/widgets/game_action_bar.dart';
import 'package:another_mine/widgets/mine_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:willshex/willshex.dart';

class GamePage extends StatefulWidget {
  static const routePath = "/game/:difficulty";
  static GoRouterWidgetBuilder builder = (context, state) {
    final String? difficultyParam = state.pathParameters["difficulty"];
    GameDifficultyType difficulty = GameDifficultyType.values.firstWhere(
        (e) => e.name == difficultyParam,
        orElse: () => GameDifficultyType.beginner);

    BlocProvider.of<GameBloc>(context).add(NewGame(difficulty: difficulty));

    return GamePage._(difficulty);
  };

  static String buildRoute([
    GameDifficultyType difficulty = GameDifficultyType.beginner,
  ]) =>
      routePath.replaceAll(":difficulty", difficulty.name);

  final GameDifficultyType difficulty;
  const GamePage._(this.difficulty);

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
