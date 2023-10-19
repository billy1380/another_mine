enum TileStateType {
  notPressed,
  one(1),
  two(2),
  three(3),
  four(4),
  five(5),
  six(6),
  seven(7),
  eight(8),
  predictedBombCorrect,
  predictedBombIncorrect,
  revealedBomb,
  detenateBomb,
  revealedSafe(0),
  unsure,
  ;

  final int value;
  const TileStateType([this.value = -1]);

  static TileStateType from(int value) {
    TileStateType found = TileStateType.notPressed;
    switch (value) {
      case 1:
        found = TileStateType.one;
        break;
      case 2:
        found = TileStateType.two;
        break;
      case 3:
        found = TileStateType.three;
        break;
      case 4:
        found = TileStateType.four;
        break;
      case 5:
        found = TileStateType.five;
        break;
      case 6:
        found = TileStateType.six;
        break;
      case 7:
        found = TileStateType.seven;
        break;
      case 8:
        found = TileStateType.eight;
        break;
    }

    return found;
  }
}
