import 'package:another_mine/bloc/game/game_bloc.dart';
import 'package:another_mine/model/tile_state_type.dart';
import 'package:another_mine/model/tilemodel.dart';

class Guesser {
  final GameBloc game;

  Guesser(this.game);

  void makeAMove() {
    bool clicked = false;
    int flagged, notPressed;

    List<TileModel> numbers = game.state.tiles
        .where((t) => t.state.value > 0 && t.state.value <= 8)
        .toList();

    for (TileModel tile in numbers) {
      flagged = 0;
      notPressed = 0;

      for (int i = 0; i < tile.neighbours.length; i++) {
        if (tile.neighbours[i] != null) {
          final TileModel neighbour = tile.neighbours[i]!;

          if (neighbour.state == TileStateType.notPressed ||
              neighbour.state == TileStateType.unsure) {
            notPressed++;
          } else if (neighbour.state == TileStateType.predictedBombCorrect) {
            flagged++;
          }
        }
      }

      if (TileStateType.from(notPressed + flagged) == tile.state) {
        if (notPressed > 0) {
          for (int i = 0; i < tile.neighbours.length; i++) {
            if (tile.neighbours[i] != null) {
              final TileModel neighbour = tile.neighbours[i]!;

              if (neighbour.state != TileStateType.predictedBombCorrect) {
                clicked = true;
                game.add(Speculate(model: neighbour));
              }
            }
          }

          break;
        }
      }

      if (TileStateType.from(flagged) == tile.state && notPressed > 0) {
        clicked = true;
        game.add(Probe(model: tile));
      }

      if (clicked) break;
    }

    if (game.state.isNotFinished && !clicked) {
      List<TileModel> remaining = game.state.tiles
          .where((t) => t.state == TileStateType.notPressed)
          .toList();
      clicked = true;
      game.add(Probe(model: remaining[random(remaining.length)]));
    }
  }
}
