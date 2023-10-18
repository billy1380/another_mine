enum TileStateType {
  notPressed,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  predictedBombCorrect,
  predictedBombIncorrect,
  revealedBomb,
  detenateBomb,
  revealedSafe,
  unsure
}

TileStateType convertToTileState(int value) {
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
