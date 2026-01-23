import "dart:math";

import "package:another_mine/logic/game_builder.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/tile_model.dart";
import "package:another_mine/model/tile_state_type.dart";
import "package:flutter/material.dart";

class RandomGameBuilder extends GameBuilder {
  final Random _random;

  RandomGameBuilder([Random? random]) : _random = random ?? Random();

  @override
  List<TileModel> build(GameDifficulty difficulty, Color colour) {
    return _createMineMap(difficulty, colour);
  }

  List<TileModel> _createMineMap(
    GameDifficulty difficulty,
    Color colour,
  ) {
    int tileCount = difficulty.area;
    List<TileModel> tiles = [
      for (int i = 0; i < tileCount; i++)
        TileModel()
          ..hasMine = false
          ..colour = Color.fromARGB(
              76 + _random.nextInt(179),
              (colour.r * 255.0).round().clamp(0, 255),
              (colour.g * 255.0).round().clamp(0, 255),
              (colour.b * 255.0).round().clamp(0, 255))
          ..index = i
          ..state = TileStateType.notPressed
          ..clearNeighbours(),
    ];

    int k, allocatedMines = 0;
    bool newPosition;
    List<int> mineLocations = List<int>.filled(tileCount, 0);

    while (allocatedMines < difficulty.mines) {
      newPosition = true;
      mineLocations[allocatedMines] = _random.nextInt(tileCount);

      for (k = 0; k < allocatedMines; k++) {
        if (mineLocations[k] == mineLocations[allocatedMines]) {
          newPosition = false;
          break;
        }
      }

      if (newPosition) {
        tiles[mineLocations[allocatedMines]].hasMine = true;
        allocatedMines++;
      }
    }

    GameBuilder.updateMineCountAndNeighbours(difficulty, tiles);

    return tiles;
  }
}
