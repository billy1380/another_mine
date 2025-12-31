import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/model/tile_state_type.dart";

class ProbabilityCalculator {
  static List<double> calculate(GameState state) {
    if (state.status == GameStateType.lost ||
        state.status == GameStateType.won) {
      return List.filled(state.tiles.length, 0.0);
    }

    if (state.start == null) {
      return List.filled(state.tiles.length, 0.0);
    }

    final int totalTiles = state.tiles.length;
    final List<double> probabilities = List.filled(totalTiles, -1.0);

    // 1. Mark knowns (Opened or Flagged)
    _markKnownTiles(state, probabilities);

    // 2. Iterative Trivial Solver (Constraint Propagation)
    _applyIterativeConstraints(state, probabilities);

    // 3. Solve Islands (Connected Components)
    _solveIslands(state, probabilities);

    // 4. Global probability for non-boundary tiles
    _calculateGlobalProbabilities(state, probabilities);

    return probabilities;
  }

  static void _markKnownTiles(GameState state, List<double> probabilities) {
    for (int i = 0; i < state.tiles.length; i++) {
      final tile = state.tiles[i];
      if (tile.state == TileStateType.predictedBombCorrect) {
        probabilities[i] = 1.0;
      } else if (tile.state != TileStateType.notPressed &&
          tile.state != TileStateType.unsure) {
        probabilities[i] = 0.0;
      }
    }
  }

  static void _applyIterativeConstraints(
      GameState state, List<double> probabilities) {
    // 1.5 Iterative Trivial Solver (Constraint Propagation)
    // Reduce the search space by solving simple constraints before building islands
    bool changed = true;
    while (changed) {
      changed = false;
      for (int i = 0; i < state.tiles.length; i++) {
        final tile = state.tiles[i];
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

          // All remaining neighbors must be mines
          if (minesNeeded - markedNeighbors == unknownNeighbors.length) {
            for (var idx in unknownNeighbors) {
              probabilities[idx] = 1.0;
            }
            changed = true;
          }
          // All remaining neighbors must be safe
          else if (minesNeeded - markedNeighbors == 0) {
            for (var idx in unknownNeighbors) {
              probabilities[idx] = 0.0;
            }
            changed = true;
          }
        }
      }
    }
  }

  static void _solveIslands(GameState state, List<double> probabilities) {
    // 2. Identify "Boundary" tiles and "Constraint" numbers
    // A tile is a "Boundary" if it is unrevealed and adjacent to a revealed number.
    // A "Constraint" is a revealed number tile adjacent to at least one unrevealed tile.

    Set<int> boundaryTiles = {};
    Set<int> constraints = {};

    for (int i = 0; i < state.tiles.length; i++) {
      final tile = state.tiles[i];
      // If tile is a revealed number (constraint)
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

    // 3. Group into Islands (Connected Components)
    // Build adjacency: Constraint <-> Boundary Tile
    // If a Constraint touches a Boundary Tile, they are connected.
    // We want properly separated sets of (Constraints + BoundaryTiles).

    // Map from (Constraint Index) -> List of (Boundary Indices)
    Map<int, List<int>> constraintToBoundary = {};
    // Map from (Boundary Index) -> List of (Constraint Indices)
    Map<int, List<int>> boundaryToConstraint = {};

    for (int cIdx in constraints) {
      constraintToBoundary[cIdx] = [];
      for (var n in state.tiles[cIdx].neighbours) {
        if (n != null && boundaryTiles.contains(n.index)) {
          constraintToBoundary[cIdx]!.add(n.index);

          boundaryToConstraint.putIfAbsent(n.index, () => []);
          boundaryToConstraint[n.index]!.add(cIdx);
        }
      }
    }

    // Connected components search
    Set<int> visitedConstraints = {};
    List<List<int>> islands = []; // Each island is list of Constraint Indices

    for (int cIdx in constraints) {
      if (visitedConstraints.contains(cIdx)) continue;

      List<int> island = [];
      List<int> queue = [cIdx];
      visitedConstraints.add(cIdx);

      while (queue.isNotEmpty) {
        int current = queue.removeLast();
        island.add(current);

        // Neighbors of constraint are boundary tiles
        for (int bIdx in constraintToBoundary[current]!) {
          // Neighbors of boundary tile are constraints
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

    // 4. Solve each island
    for (List<int> island in islands) {
      _solveIsland(island, constraintToBoundary, state, probabilities);
    }
  }

  static void _calculateGlobalProbabilities(
      GameState state, List<double> probabilities) {
    // 5. Global probability for non-boundary tiles
    // Count mines known (marked) + mines deduced as 100% in islands?
    // For simplicity, we stick to the basic "remainder" logic but we should be careful about
    // probability mass used up by islands.
    // A simplified approach:
    //   Remaining Mines = Total - Marked.
    //   But "Marked" in probability array might have increased (if we found 100% ones).
    //   Also, valid solutions for islands consume mines.
    //   Approximation: Calculate expected number of mines in islands.
    //   E_mines_islands = sum(P(t)) for t in all boundary tiles.
    //   Mines_for_rest = Total_Mines - E_mines_islands - Already_Marked_Pre_Alg.
    //   Rest_Prob = Mines_for_rest / Count_of_rest_tiles.

    // Re-verify island contribution logic or simplify
    // We can rely on summing probabilities of all island tiles (that are not -1.0)

    // We iterate over all tiles to find ones that were solved (prob > 0 && < 1... etc)
    // Actually simpler: iterate over all tiles, if prob != -1.0 (and not initially marked), add to expected sum?
    // Wait, initially marked (flagged) have prob 1.0.
    // Revealed have prob 0.0.
    // Solved islands have prob between 0.0 and 1.0.

    // So if we just sum ALL probabilities, we get Expected Total Mines from solved/known areas.
    // Sum includes user flags (1.0).

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

    double remainingMines =
        state.difficulty.mines.toDouble() - solvedExpectedMines;

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
      GameState state,
      List<double> probabilities) {
    // key: boundary tile index, value: index in "variables" list
    Map<int, int> tileToIndex = {};
    List<int> variables = []; // The boundary tiles we need to assign

    for (int cIdx in islandConstraints) {
      for (int bIdx in constraintToBoundary[cIdx]!) {
        if (!tileToIndex.containsKey(bIdx)) {
          tileToIndex[bIdx] = variables.length;
          variables.add(bIdx);
        }
      }
    }

    // Store solutions counts: how many valid solutions have tile X as mine
    List<int> mineCounts = List.filled(variables.length, 0);
    int totalSolutions = 0;

    // Pre-process constraints for speed
    // Each constraint: { mines_needed, [list_of_variable_indices] }
    List<MapEntry<int, List<int>>> processedConstraints = [];

    for (int cIdx in islandConstraints) {
      int totalMinesNeeded = state.tiles[cIdx].neigbouringMine;
      // Subtract already marked/flagged neighbors (prob == 1.0)
      // (These are NOT in "variables" because they aren't -1.0)
      // GameState neighbours include everything.
      int currentMarked = 0;
      for (var n in state.tiles[cIdx].neighbours) {
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

    // Backtracking
    // assignment: 0=safe, 1=mine
    List<int> assignment = List.filled(variables.length, 0);

    void backtrack(int index) {
      if (index == variables.length) {
        // Verify all constraints one last time (optimizable via forward checking)
        for (var c in processedConstraints) {
          int mines = 0;
          for (int vIdx in c.value) {
            if (assignment[vIdx] == 1) mines++;
          }
          if (mines != c.key) return; // Invalid
        }

        // Valid solution found
        totalSolutions++;
        for (int i = 0; i < variables.length; i++) {
          if (assignment[i] == 1) mineCounts[i]++;
        }
        return;
      }

      // Optimization: Check partial constraints
      // For the current variable 'index' being assigned, check constraints that *only* involve variables < index?
      // Simpler: Just check constraints where all variables are assigned.
      // Even better: Pruning based on "min possible" and "max possible" for each constraint.
      // Let's implement basic pruning.

      // Try assigning 0 (Safe)
      assignment[index] = 0;
      if (_isValidPartial(processedConstraints, assignment, index)) {
        backtrack(index + 1);
      }

      // Try assigning 1 (Mine)
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

      // Pruning condition 1: Too many mines already
      if (mines > c.key) return false;

      // Pruning condition 2: Not enough space to fit needed mines
      if (mines + unassigned < c.key) return false;
    }
    return true;
  }
}
