enum TileState {
  NotPressed,
  One,
  Two,
  Three,
  Four,
  Five,
  Six,
  Seven,
  Eight,
  PredictedBombCorrect,
  PredictedBombIncorrect,
  RevealedBomb,
  DetenateBomb,
  RevealedSafe,
  Unsure
}

TileState convertToTileState(int value) {
    TileState found = TileState.NotPressed;
    switch (value) {
      case 1:
        found = TileState.One;
        break;
      case 2:
        found = TileState.Two;
        break;
      case 3:
        found = TileState.Three;
        break;
      case 4:
        found = TileState.Four;
        break;
      case 5:
        found = TileState.Five;
        break;
      case 6:
        found = TileState.Six;
        break;
      case 7:
        found = TileState.Seven;
        break;
      case 8:
        found = TileState.Eight;
        break;
    }

    return found;
  }
