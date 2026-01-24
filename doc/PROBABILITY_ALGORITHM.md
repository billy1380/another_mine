# Probability Calculator Algorithm

This document details the algorithm used in `lib/logic/probability_calculator.dart` to determine the probability of a tile containing a mine.

## Overview

The calculator uses a multi-step process involving constraint propagation, connected component analysis (islands), and backtracking to solve the board.

## Steps

### 1. Mark Known Tiles
Identify tiles that are already revealed (safe, probability 0.0) or flagged (mine, probability 1.0).

### 2. Iterative Trivial Solver (Constraint Propagation)
Reduces the search space by solving simple local constraints before attempting complex analysis.
-   Iterates through all revealed number tiles.
-   **Safe Rule**: If `mines_needed - marked_neighbors == 0`, all remaining hidden neighbors are safe (0.0).
-   **Mine Rule**: If `mines_needed - marked_neighbors == unknown_neighbors_count`, all remaining hidden neighbors are mines (1.0).
-   Repeats until no more changes occur.

### 3. Solve Islands (Connected Components)
Decomposes the board into independent "islands" to solve them efficiently.
-   **Boundary Tiles**: Unrevealed tiles adjacent to a revealed number.
-   **Constraint Tiles**: Revealed number tiles adjacent to at least one unrevealed tile.
-   **Grouping**: Builds an adjacency graph where Constraints link to Boundary Tiles. Connected components of this graph form "islands". Each island is independent and can be solved separately.

### 4. Backtracking Solver (Per Island)
For each island, finds all valid mine configurations using backtracking.
-   **Variables**: The boundary tiles in the island.
-   **Constraints**: The numbers on the constraint tiles.
-   **Algorithm**:
    -   Recursively assigns "Mine" or "Safe" to each variable.
    -   Prunes branches that violate constraints (e.g., too many mines or not enough space).
    -   Counts how many valid solutions have tile X as a mine (`mine_counts[X]`).
    -   `Probability(X) = mine_counts[X] / total_valid_solutions`.

### 5. Global Probability (Non-Boundary Tiles)
Calculates the probability for tiles not adjacent to any number (floating tiles).
-   `Expected_Mines_Used = Sum(Probability(t))` for all solved boundary tiles.
-   `Remaining_Mines = Total_Mines - Expected_Mines_Used - Flagged_Mines`.
-   `Floating_Prob = Remaining_Mines / Count_of_Floating_Tiles`.
-   This assigns a uniform probability to all tiles outside the influence of revealed numbers.
