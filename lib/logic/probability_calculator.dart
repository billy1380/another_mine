import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/model/tile_model.dart";
import "package:another_mine/model/tile_state_type.dart";

class ProbabilityCalculator {
  static List<double> calculate(
    List<TileModel> tiles,
    GameDifficulty difficulty,
    GameStateType status,
  ) {
    if (status == GameStateType.lost || status == GameStateType.won) {
      return List.filled(tiles.length, 0.0);
    }

    if (status == GameStateType.notStarted) {
      return List.filled(tiles.length, 0.0);
    }

    final int totalTiles = tiles.length;
    final List<double> probabilities = List.filled(totalTiles, -1.0);

    _markKnownTiles(tiles, probabilities);
    _applyIterativeConstraints(tiles, probabilities);
    _solveIslands(tiles, probabilities);
    _calculateGlobalProbabilities(tiles, difficulty, probabilities);

    return probabilities;
  }

  static void _markKnownTiles(
      List<TileModel> tiles, List<double> probabilities) {
    for (int i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      if (tile.state == TileStateType.predictedBombCorrect) {
        probabilities[i] = 1.0;
      } else if (tile.state != TileStateType.notPressed &&
          tile.state != TileStateType.unsure) {
        probabilities[i] = 0.0;
      }
    }
  }

  static void _applyIterativeConstraints(
      List<TileModel> tiles, List<double> probabilities) {
    bool changed = true;
    while (changed) {
      changed = false;
      for (int i = 0; i < tiles.length; i++) {
        final tile = tiles[i];
        if (tile.state.index >= TileStateType.one.index &&
            tile.state.index <= TileStateType.eight.index) {
          int minesNeeded = tile.neigbouringMine;
          int markedNeighbors = 0;
          List<int> unknownNeighbors = [];

          for (var n in tile.neighbours) {
            if (n != null) {
              if (probabilities[n.index] == 1.0) {
                markedNeighbors++;
              } else if (probabilities[n.index] == -1.0) {
                unknownNeighbors.add(n.index);
              }
            }
          }

          if (unknownNeighbors.isEmpty) continue;

          if (minesNeeded - markedNeighbors == unknownNeighbors.length) {
            for (var idx in unknownNeighbors) {
              probabilities[idx] = 1.0;
            }
            changed = true;
          } else if (minesNeeded - markedNeighbors == 0) {
            for (var idx in unknownNeighbors) {
              probabilities[idx] = 0.0;
            }
            changed = true;
          }
        }
      }
    }
  }

  static void _solveIslands(List<TileModel> tiles, List<double> probabilities) {
    Set<int> boundaryTiles = {};
    Set<int> constraints = {};

    for (int i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      if (tile.state.index >= TileStateType.one.index &&
          tile.state.index <= TileStateType.eight.index) {
        bool hasUnrevealedNeighbor = false;
        for (var n in tile.neighbours) {
          if (n != null && probabilities[n.index] == -1.0) {
            hasUnrevealedNeighbor = true;
            boundaryTiles.add(n.index);
          }
        }
        if (hasUnrevealedNeighbor) {
          constraints.add(i);
        }
      }
    }

    Map<int, List<int>> constraintToBoundary = {};
    Map<int, List<int>> boundaryToConstraint = {};

    for (int cIdx in constraints) {
      constraintToBoundary[cIdx] = [];
      for (var n in tiles[cIdx].neighbours) {
        if (n != null && boundaryTiles.contains(n.index)) {
          constraintToBoundary[cIdx]!.add(n.index);

          boundaryToConstraint.putIfAbsent(n.index, () => []);
          boundaryToConstraint[n.index]!.add(cIdx);
        }
      }
    }

    Set<int> visitedConstraints = {};
    List<List<int>> islands = [];

    for (int cIdx in constraints) {
      if (visitedConstraints.contains(cIdx)) continue;

      List<int> island = [];
      List<int> queue = [cIdx];
      visitedConstraints.add(cIdx);

      while (queue.isNotEmpty) {
        int current = queue.removeLast();
        island.add(current);

        for (int bIdx in constraintToBoundary[current]!) {
          for (int nextC in boundaryToConstraint[bIdx]!) {
            if (!visitedConstraints.contains(nextC)) {
              visitedConstraints.add(nextC);
              queue.add(nextC);
            }
          }
        }
      }
      islands.add(island);
    }

    for (List<int> island in islands) {
      _solveIsland(island, constraintToBoundary, tiles, probabilities);
    }
  }

  static void _calculateGlobalProbabilities(List<TileModel> tiles,
      GameDifficulty difficulty, List<double> probabilities) {
    double solvedExpectedMines = 0.0;
    int floatingCount = 0;
    List<int> floatingIndices = [];

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] != -1.0) {
        solvedExpectedMines += probabilities[i];
      } else {
        floatingCount++;
        floatingIndices.add(i);
      }
    }

    double remainingMines = difficulty.mines.toDouble() - solvedExpectedMines;

    double floatingProb = 0.0;
    if (floatingCount > 0) {
      floatingProb = (remainingMines / floatingCount).clamp(0.0, 1.0);
    }

    for (int idx in floatingIndices) {
      probabilities[idx] = floatingProb;
    }
  }

  static void _solveIsland(
      List<int> islandConstraints,
      Map<int, List<int>> constraintToBoundary,
      List<TileModel> tiles,
      List<double> probabilities) {
    Map<int, int> tileToIndex = {};
    List<int> variables = [];

    for (int cIdx in islandConstraints) {
      for (int bIdx in constraintToBoundary[cIdx]!) {
        if (!tileToIndex.containsKey(bIdx)) {
          tileToIndex[bIdx] = variables.length;
          variables.add(bIdx);
        }
      }
    }

    List<int> mineCounts = List.filled(variables.length, 0);
    int totalSolutions = 0;

    List<MapEntry<int, List<int>>> processedConstraints = [];

    for (int cIdx in islandConstraints) {
      int totalMinesNeeded = tiles[cIdx].neigbouringMine;
      int currentMarked = 0;
      for (var n in tiles[cIdx].neighbours) {
        if (n != null && probabilities[n.index] == 1.0) {
          currentMarked++;
        }
      }

      int minesNeeded = totalMinesNeeded - currentMarked;

      List<int> varIndices = [];
      for (int bIdx in constraintToBoundary[cIdx]!) {
        varIndices.add(tileToIndex[bIdx]!);
      }

      processedConstraints.add(MapEntry(minesNeeded, varIndices));
    }

    List<int> assignment = List.filled(variables.length, 0);

    void backtrack(int index) {
      if (index == variables.length) {
        for (var c in processedConstraints) {
          int mines = 0;
          for (int vIdx in c.value) {
            if (assignment[vIdx] == 1) mines++;
          }
          if (mines != c.key) return;
        }

        totalSolutions++;
        for (int i = 0; i < variables.length; i++) {
          if (assignment[i] == 1) mineCounts[i]++;
        }
        return;
      }

      assignment[index] = 0;
      if (_isValidPartial(processedConstraints, assignment, index)) {
        backtrack(index + 1);
      }

      assignment[index] = 1;
      if (_isValidPartial(processedConstraints, assignment, index)) {
        backtrack(index + 1);
      }
    }

    backtrack(0);

    if (totalSolutions > 0) {
      for (int i = 0; i < variables.length; i++) {
        probabilities[variables[i]] =
            (mineCounts[i] / totalSolutions).clamp(0.0, 1.0);
      }
    }
  }

  static bool _isValidPartial(List<MapEntry<int, List<int>>> constraints,
      List<int> assignment, int currentIndex) {
    for (var c in constraints) {
      int mines = 0;
      int unassigned = 0;

      for (int vIdx in c.value) {
        if (vIdx <= currentIndex) {
          mines += assignment[vIdx];
        } else {
          unassigned++;
        }
      }

      if (mines > c.key) return false;

      if (mines + unassigned < c.key) return false;
    }
    return true;
  }
}
