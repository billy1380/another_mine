import "package:another_mine/ai/interaction_type.dart";

class GameMove {
  final int x, y;
  final InteractionType type;

  const GameMove({
    this.x = -1,
    this.y = -1,
    this.type = InteractionType.none,
  });
}
