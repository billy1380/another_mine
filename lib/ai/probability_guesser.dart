import "dart:math";

import "package:another_mine/ai/simple_guesser.dart";
import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/logic/probability_calculator.dart";
import "package:another_mine/model/tile_state_type.dart";

class ProbabilityGuesser extends SimpleGuesser {
  ProbabilityGuesser(super.game);

  @override
  void makeAMove() {
    if (game.state.isFinished) return;

    // 1. Calculate probabilities for all tiles
    List<double> probabilities = ProbabilityCalculator.calculate(game.state);

    List<int> safeTiles = [];
    List<int> mineTiles = [];
    List<int> uncertainTiles = [];

    // 2. Classify unrevealed tiles
    for (int i = 0; i < game.state.tiles.length; i++) {
      final tile = game.state.tiles[i];
      
      // We only care about tiles that are not yet revealed or fully processed
      if (tile.state == TileStateType.notPressed ||
          tile.state == TileStateType.unsure) {
        
        double p = probabilities[i];
        
        if (p == 0.0) {
          safeTiles.add(i);
        } else if (p == 1.0) {
          mineTiles.add(i);
        } else if (p > 0.0 && p < 1.0) {
          uncertainTiles.add(i);
        }
        // p == -1.0 means unknown/unreachable/error, usually ignore or treat as uncertain
        // If the calculator returns -1.0 for everything (e.g. error), we fall back to random
        else if (p == -1.0) {
           uncertainTiles.add(i);
        }
      }
    }

    // 3. Execute moves based on priority

    // Priority 1: Reveal known safe tiles
    if (safeTiles.isNotEmpty) {
      // Pick one randomly to avoid bias if there are many, or just the first
      // Random is better for variety in testing
      int idx = safeTiles[Random().nextInt(safeTiles.length)];
      game.add(Probe(model: game.state.tiles[idx]));
      return;
    }

    // Priority 2: Flag known mines
    if (mineTiles.isNotEmpty) {
      int idx = mineTiles[Random().nextInt(mineTiles.length)];
      game.add(Speculate(model: game.state.tiles[idx]));
      return;
    }

    // Priority 3: Make the best guess (lowest probability of being a mine)
    if (uncertainTiles.isNotEmpty) {
      // Find the tile with the minimum probability
      double minP = 100.0;
      List<int> bestCandidates = [];

      for (int idx in uncertainTiles) {
        double p = probabilities[idx];
        if (p == -1.0) continue; // Skip strictly unknown if we have other options? 
        // Actually -1.0 might be "floating" which is calculated as global probability usually.
        // If ProbabilityCalculator returns -1.0 it means it didn't calculate it.
        // In _calculateGlobalProbabilities, it fills -1.0s with floatingProb.
        // So -1.0 shouldn't exist if calculate completes. 
        // But if it does, let's treat it as high risk? Or average?
        
        if (p < minP) {
          minP = p;
          bestCandidates = [idx];
        } else if (p == minP) {
          bestCandidates.add(idx);
        }
      }

      if (bestCandidates.isNotEmpty) {
        int idx = bestCandidates[Random().nextInt(bestCandidates.length)];
        game.add(Probe(model: game.state.tiles[idx]));
        return;
      }
    }

    // Priority 4: If no info (e.g. start of game or calculator failure), random move
    // This handles the case where all valid tiles had prob -1.0 or list was empty (shouldn't happen if game not finished)
    
    // Use the base class's random fallback logic if appropriate, 
    // or just implement a simple random probe.
    List<int> allRemaining = [];
     for (int i = 0; i < game.state.tiles.length; i++) {
      final tile = game.state.tiles[i];
      if (tile.state == TileStateType.notPressed || tile.state == TileStateType.unsure) {
        allRemaining.add(i);
      }
    }

    if (allRemaining.isNotEmpty) {
      int idx = allRemaining[Random().nextInt(allRemaining.length)];
      game.add(Probe(model: game.state.tiles[idx]));
    }
  }
}
