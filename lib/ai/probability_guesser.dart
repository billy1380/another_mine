import "package:another_mine/ai/game_move.dart";
import "package:another_mine/ai/random_guesser.dart";
import "package:another_mine/logic/probability_calculator.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/model/tile_model.dart";
import "package:another_mine/model/tile_state_type.dart";

class ProbabilityGuesser extends RandomGuesser {
  const ProbabilityGuesser(super._random);

  @override
  GameMove makeAMove(
    List<TileModel> tiles,
    GameDifficulty difficulty,
    GameStateType status,
  ) {
    if (status == GameStateType.won || status == GameStateType.lost) {
      return const GameMove(type: InteractionType.none);
    }

    List<double> probabilities =
        ProbabilityCalculator.calculate(tiles, difficulty, status);

    List<int> safeTiles = [];
    List<int> mineTiles = [];
    List<int> uncertainTiles = [];

    for (int i = 0; i < tiles.length; i++) {
      final tile = tiles[i];

      if (tile.state == TileStateType.notPressed ||
          tile.state == TileStateType.unsure) {
        double p = probabilities[i];

        if (p == 0.0) {
          safeTiles.add(i);
        } else if (p == 1.0) {
          mineTiles.add(i);
        } else {
          uncertainTiles.add(i);
        }
      }
    }

    if (mineTiles.isNotEmpty) {
      int idx = mineTiles[nextRandom(mineTiles.length)];
      return GameMove(
        x: idx % difficulty.width,
        y: idx ~/ difficulty.width,
        type: InteractionType.speculate,
      );
    }

    if (safeTiles.isNotEmpty) {
      int idx = safeTiles[nextRandom(safeTiles.length)];
      return GameMove(
        x: idx % difficulty.width,
        y: idx ~/ difficulty.width,
        type: InteractionType.probe,
      );
    }

    if (uncertainTiles.isNotEmpty) {
      double minP = 100.0;
      List<int> bestCandidates = [];

      for (int idx in uncertainTiles) {
        double p = probabilities[idx];
        if (p == -1.0) {
          continue;
        }

        if (p < minP) {
          minP = p;
          bestCandidates = [idx];
        } else if (p == minP) {
          bestCandidates.add(idx);
        }
      }

      if (bestCandidates.isNotEmpty) {
        int idx = bestCandidates[nextRandom(bestCandidates.length)];
        return GameMove(
          x: idx % difficulty.width,
          y: idx ~/ difficulty.width,
          type: InteractionType.probe,
        );
      }
    }

    List<int> allRemaining = [];
    for (int i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      if (tile.state == TileStateType.notPressed ||
          tile.state == TileStateType.unsure) {
        allRemaining.add(i);
      }
    }

    if (allRemaining.isNotEmpty) {
      int idx = allRemaining[nextRandom(allRemaining.length)];
      return GameMove(
        x: idx % difficulty.width,
        y: idx ~/ difficulty.width,
        type: InteractionType.probe,
      );
    }

    return const GameMove(type: InteractionType.none);
  }
}
