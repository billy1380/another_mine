import "package:another_mine/ai/random_guesser.dart";
import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/logic/probability_calculator.dart";
import "package:another_mine/model/tile_state_type.dart";

class ProbabilityGuesser extends RandomGuesser {
  const ProbabilityGuesser(super._random, super.game);

  @override
  void makeAMove() {
    if (game.state.isFinished) {
      return;
    }

    List<double> probabilities = ProbabilityCalculator.calculate(game.state);

    List<int> safeTiles = [];
    List<int> mineTiles = [];
    List<int> uncertainTiles = [];

    for (int i = 0; i < game.state.tiles.length; i++) {
      final tile = game.state.tiles[i];

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
      game.add(Speculate(model: game.state.tiles[idx]));
      return;
    }

    if (safeTiles.isNotEmpty) {
      int idx = safeTiles[nextRandom(safeTiles.length)];
      game.add(Probe(model: game.state.tiles[idx]));
      return;
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
        game.add(Probe(model: game.state.tiles[idx]));
        return;
      }
    }

    List<int> allRemaining = [];
    for (int i = 0; i < game.state.tiles.length; i++) {
      final tile = game.state.tiles[i];
      if (tile.state == TileStateType.notPressed ||
          tile.state == TileStateType.unsure) {
        allRemaining.add(i);
      }
    }

    if (allRemaining.isNotEmpty) {
      int idx = allRemaining[nextRandom(allRemaining.length)];
      game.add(Probe(model: game.state.tiles[idx]));
    }
  }
}
