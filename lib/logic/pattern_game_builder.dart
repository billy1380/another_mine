import "dart:ui";

import "package:another_mine/logic/game_builder.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/tile_model.dart";
import "package:another_mine/model/tile_state_type.dart";

class PatternGameBuilder extends GameBuilder {
  final List<List<bool>> pattern;

  const PatternGameBuilder(this.pattern);

  @override
  List<TileModel> build(GameDifficulty difficulty, Color colour) {
    int height = pattern.length;
    int width = pattern.isEmpty ? 0 : pattern[0].length;

    List<TileModel> tiles = [];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        bool hasMine = pattern[y][x];

        tiles.add(TileModel()
          ..hasMine = hasMine
          ..colour = colour
          ..index = (y * width) + x
          ..state = TileStateType.notPressed
          ..clearNeighbours());
      }
    }

    GameBuilder.updateMineCountAndNeighbours(difficulty, tiles);

    return tiles;
  }
}
