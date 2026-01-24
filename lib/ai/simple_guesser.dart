import "package:another_mine/ai/game_move.dart";
import "package:another_mine/ai/random_guesser.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/model/tile_model.dart";
import "package:another_mine/model/tile_state_type.dart";

class SimpleGuesser extends RandomGuesser {
  const SimpleGuesser(super._random);

  @override
  GameMove makeAMove(
    List<TileModel> tiles,
    GameDifficulty difficulty,
    GameStateType status,
  ) {
    int flagged, notPressed;

    List<TileModel> numbers = tiles
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
                return GameMove(
                  x: neighbour.index % difficulty.width,
                  y: neighbour.index ~/ difficulty.width,
                  type: InteractionType.speculate,
                );
              }
            }
          }
        }
      }

      if (TileStateType.from(flagged) == tile.state && notPressed > 0) {
        return GameMove(
          x: tile.index % difficulty.width,
          y: tile.index ~/ difficulty.width,
          type: InteractionType.probe,
        );
      }
    }

    if (status != GameStateType.won && status != GameStateType.lost) {
      List<TileModel> remaining = tiles
          .where((t) => t.state == TileStateType.notPressed)
          .toList();

      if (remaining.isNotEmpty) {
        TileModel tile = remaining[nextRandom(remaining.length)];
        return GameMove(
          x: tile.index % difficulty.width,
          y: tile.index ~/ difficulty.width,
          type: InteractionType.probe,
        );
      }
    }

    return const GameMove(type: InteractionType.none);
  }
}
