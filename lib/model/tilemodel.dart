import 'package:another_mine/model/tilestate.dart';
import 'package:flutter/material.dart';

class TileModel {
  late TileState state;
  late bool hasMine;
  late Color colour;
  late int index;
  // GameDifficulty difficulty;
  List<TileModel?> neighbours = List<TileModel?>.filled(8, null);
  late int neigbouringMine;

  void setNeightbourAt(int index, TileModel model) {
    int i = index;
    if (i > 4) {
      i--;
    }
    neighbours[i] = model;
  }

  bool probe() {
    TileState before = state;

    if (state != TileState.predictedBombCorrect) {
      if (hasMine) {
        state = TileState.detenateBomb;
      } else {
        state = TileState.revealedSafe;

        switch (neigbouringMine) {
          case 1:
            state = TileState.one;
            break;
          case 2:
            state = TileState.two;
            break;
          case 3:
            state = TileState.three;
            break;
          case 4:
            state = TileState.four;
            break;
          case 5:
            state = TileState.five;
            break;
          case 6:
            state = TileState.six;
            break;
          case 7:
            state = TileState.seven;
            break;
          case 8:
            state = TileState.eight;
            break;
        }
      }
    }

    return state != before;
  }

  void speculate() {
    switch (state) {
      case TileState.predictedBombCorrect:
        state = TileState.unsure;
        break;
      case TileState.unsure:
        state = TileState.notPressed;
        break;
      case TileState.notPressed:
        state = TileState.predictedBombCorrect;
        break;
      default:
        break;
    }
  }

  void reveal() {
    switch (state) {
      case TileState.predictedBombCorrect:
        if (!hasMine) {
          state = TileState.predictedBombIncorrect;
        }
        break;
      case TileState.unsure:
      case TileState.notPressed:
        if (hasMine) {
          state = TileState.revealedBomb;
        } else {
          probe();
        }
        break;
      default:
        break;
    }
  }

  void clearNeighbours() {
    for (int i = 0; i < neighbours.length; i++) {
      neighbours[i] = null;
    }
  }
}
