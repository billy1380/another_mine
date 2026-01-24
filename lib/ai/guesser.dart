import "package:another_mine/ai/game_move.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/model/tile_model.dart";

abstract class Guesser {
  const Guesser();

  GameMove makeAMove(
    List<TileModel> tiles,
    GameDifficulty difficulty,
    GameStateType status,
  );
}
