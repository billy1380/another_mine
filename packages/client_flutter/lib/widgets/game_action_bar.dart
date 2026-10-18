import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_common/presentation/presentation.dart";
import "package:another_mine_flutter/assets.dart";
import "package:another_mine_flutter/extensions/colour_ex.dart";
import "package:another_mine_flutter/widgets/digits.dart";
import "package:another_mine_flutter/widgets/game_timer.dart";
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
              value: state.minesRemaining,
              backgroundColor: state.colour.color,
            ),
            Tooltip(
              message: "Start new game",
              child: InkWell(
                onTap: () =>
                    BlocProvider.of<GameBloc>(context)
                        .add(NewGame(difficulty: state.difficulty)),
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AnotherMineAssets.image(
                    faceImage(state.status),
                    height: 45,
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
}
