import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/widgets/digits.dart";
import "package:another_mine/widgets/game_timer.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class GameActionBar extends StatelessWidget {
  const GameActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Digits(
              name: "Mines",
              value: state.minesMarked,
              backgroundColor: state.colour,
            ),
            Tooltip(
              message: "Start new game",
              child: InkWell(
                onTap: () => BlocProvider.of<GameBloc>(context)
                    .add(NewGame(difficulty: state.difficulty)),
                borderRadius: const BorderRadius.all(Radius.circular(5)),
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
        );
      },
    );
  }

  String _image(GameStateType state) {
    return "images/${switch (state) {
      GameStateType.lost => "restin",
      GameStateType.won => "cool",
      GameStateType.thinking => "thinking",
      _ => "well",
    }}.png";
  }
}
