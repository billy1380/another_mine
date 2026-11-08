import "dart:math";

import "package:another_mine_common/logic/game_builder.dart";
import "package:another_mine_common/model/colour.dart";
import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/model/tile_model.dart";
import "package:another_mine_common/model/tile_state_type.dart";
import "package:another_mine_common/scores/recording.dart";

/// Builds the board a game was recorded on, with its mines where they were.
class RecordedGameBuilder extends GameBuilder {
  final Recording recording;
  final Random _random;

  RecordedGameBuilder(this.recording, [Random? random])
    : _random = random ?? Random();

  @override
  List<TileModel> build(GameDifficulty difficulty, Colour colour) {
    final List<TileModel> tiles = [
      for (int i = 0; i < difficulty.area; i++)
        TileModel()
          ..hasMine = recording.hasMine(i)
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

    GameBuilder.updateMineCountAndNeighbours(difficulty, tiles);

    return tiles;
  }
}
