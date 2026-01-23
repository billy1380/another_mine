import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/tile_model.dart";
import "package:flutter/material.dart";

abstract class GameBuilder {
  const GameBuilder();

  List<TileModel> build(GameDifficulty difficulty, Color colour);

  static bool _isCurrent(int x, int y) {
    return x == 0 && y == 0;
  }

  static bool _outOfBounds(int width, int height, int x, int y) {
    return x < 0 || y < 0 || x >= width || y >= height;
  }

  static void updateMineCountAndNeighbours(
      GameDifficulty difficulty, List<TileModel> tiles) {
    int index, nIndex, count;
    for (int j = 0; j < difficulty.height; j++) {
      for (int i = 0; i < difficulty.width; i++) {
        count = 0;
        index = (j * difficulty.width) + i;
        for (int nj = -1; nj <= 1; nj++) {
          for (int ni = -1; ni <= 1; ni++) {
            if (_isCurrent(ni, nj) ||
                _outOfBounds(
                    difficulty.width, difficulty.height, i + ni, j + nj)) {
              continue;
            }

            nIndex = ((j + nj) * difficulty.width) + (i + ni);
            if (tiles[nIndex].hasMine) {
              count++;
            }

            tiles[index]
                .setNeightbourAt(((nj + 1) * 3) + (ni + 1), tiles[nIndex]);
          }
        }

        tiles[index].neigbouringMine = count;
      }
    }
  }
}
