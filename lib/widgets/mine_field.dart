import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/widgets/tile.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class Minefield extends StatelessWidget {
  const Minefield({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Tile(ValueKey(state.tiles[index].index), state.tiles[index]);
          },
          itemCount: state.tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: state.difficulty.width,
            childAspectRatio: 1.0,
          ),
        );
      },
    );
  }
}
