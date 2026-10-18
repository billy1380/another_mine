import "dart:math";

import "package:another_mine_common/logic/game_builder.dart";
import "package:another_mine_common/model/colour.dart";
import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/model/tile_model.dart";
import "package:another_mine_common/model/tile_state_type.dart";

class RandomGameBuilder extends GameBuilder {
  final Random _random;

  RandomGameBuilder([Random? random]) : _random = random ?? Random();

  @override
  List<TileModel> build(GameDifficulty difficulty, Colour colour) {
    return _createMineMap(difficulty, colour);
  }

  List<TileModel> _createMineMap(GameDifficulty difficulty, Colour colour) {
    int tileCount = difficulty.area;
    List<TileModel> tiles = [
      for (int i = 0; i < tileCount; i++)
        TileModel()
          ..hasMine = false
          ..colour = Colour.fromARGB(
            76 + _random.nextInt(179),
            colour.red,
            colour.green,
            colour.blue,
          )
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
