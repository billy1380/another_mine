import 'package:another_mine/bloc/game/game_bloc.dart';
import 'package:another_mine/model/tile_state_type.dart';
import 'package:another_mine/model/tilemodel.dart';

class Guesser {
  final GameBloc game;

  Guesser(this.game);

  void makeAMove() {
    bool clicked = false;
    int flagged, notPressed, lookingX, lookingY;
    TileModel? tile;

    for (lookingY = 0; lookingY < game.state.difficulty.height; lookingY++) {
      for (lookingX = 0; lookingX < game.state.difficulty.width; lookingX++) {
        flagged = 0;
        notPressed = 0;

        tile = game.state.tileAt(lookingX, lookingY);

        if (tile != null) {
          switch (tile.state) {
            case TileStateType.one:
            case TileStateType.two:
            case TileStateType.three:
            case TileStateType.four:
            case TileStateType.five:
            case TileStateType.six:
            case TileStateType.seven:
            case TileStateType.eight:
              for (int i = 0; i < tile.neighbours.length; i++) {
                if (tile.neighbours[i] != null) {
                  final TileModel neighbour = tile.neighbours[i]!;

                  if (neighbour.state == TileStateType.notPressed ||
                      neighbour.state == TileStateType.unsure) {
                    notPressed++;
                  } else if (neighbour.state ==
                      TileStateType.predictedBombCorrect) {
                    flagged++;
                  }
                }
              }

              if (TileStateType.from(notPressed + flagged) == tile.state) {
                if (notPressed > 0) {
                  for (int i = 0; i < tile.neighbours.length; i++) {
                    if (tile.neighbours[i] != null) {
                      final TileModel neighbour = tile.neighbours[i]!;

                      if (neighbour.state !=
                          TileStateType.predictedBombCorrect) {
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

              break;
            default:
              break;
          }
        }

        if (clicked) break;
      }

      if (clicked) break;
    }

    if (game.state.isNotFinished) {
      while (!clicked) {
        tile = game.state.tileAt(lookingX = random(game.state.difficulty.width),
            lookingY = random(game.state.difficulty.height));

        if (tile?.state == TileStateType.notPressed) {
          clicked = true;
          game.add(Probe(model: tile!));
        }
      }
    }
  }
}
