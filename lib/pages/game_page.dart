import 'package:another_mine/bloc/game/game_bloc.dart';
import 'package:another_mine/model/game_difficulty_type.dart';
import 'package:another_mine/model/game_state_type.dart';
import 'package:another_mine/pages/parts/app_drawer.dart';
import 'package:another_mine/widgets/digits.dart';
import 'package:another_mine/widgets/gametimer.dart';
import 'package:another_mine/widgets/minefield.dart';
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
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            toolbarHeight: 100,
            elevation: 0,
            title: Column(
              children: [
                Text(
                  "${StringUtils.upperCaseFirstLetter(widget.difficulty.name)} - ${StringUtils.upperCaseFirstLetter(widget.difficulty.description)}",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Digits(name: "Mines", value: state.minesMarked),
                    Tooltip(
                      message: "Start new game",
                      child: InkWell(
                        onTap: () => BlocProvider.of<GameBloc>(context)
                            .add(NewGame(difficulty: widget.difficulty)),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            height: 45,
                            _image(state.status),
                          ),
                        ),
                      ),
                    ),
                    const GameTimer(),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
              ],
            ),
          ),
          body: const Minefield(),
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

  String _image(GameStateType state) {
    String image = "well";
    switch (state) {
      case GameStateType.lost:
        image = "restin";
        break;
      case GameStateType.won:
        image = "cool";
        break;
      case GameStateType.thinking:
        image = "thinking";
        break;
      default:
        break;
    }

    return "images/$image.png";
  }
}
