class GameMove {
  final int x, y;
  final InteractionType type;

  const GameMove({
    this.x = -1,
    this.y = -1,
    this.type = InteractionType.none,
  });
}

enum InteractionType {
  none,
  probe,
  speculate,
}
