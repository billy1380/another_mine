enum TileState {
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

TileState convertToTileState(int value) {
    TileState found = TileState.notPressed;
    switch (value) {
      case 1:
        found = TileState.one;
        break;
      case 2:
        found = TileState.two;
        break;
      case 3:
        found = TileState.three;
        break;
      case 4:
        found = TileState.four;
        break;
      case 5:
        found = TileState.five;
        break;
      case 6:
        found = TileState.six;
        break;
      case 7:
        found = TileState.seven;
        break;
      case 8:
        found = TileState.eight;
        break;
    }

    return found;
  }
