import 'package:another_mine/model/tile_state_type.dart';
import 'package:flutter/material.dart';

class TileModel {
  late TileStateType state;
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
    TileStateType before = state;

    if (state != TileStateType.predictedBombCorrect) {
      if (hasMine) {
        state = TileStateType.detenateBomb;
      } else {
        state = TileStateType.revealedSafe;

        switch (neigbouringMine) {
          case 1:
            state = TileStateType.one;
            break;
          case 2:
            state = TileStateType.two;
            break;
          case 3:
            state = TileStateType.three;
            break;
          case 4:
            state = TileStateType.four;
            break;
          case 5:
            state = TileStateType.five;
            break;
          case 6:
            state = TileStateType.six;
            break;
          case 7:
            state = TileStateType.seven;
            break;
          case 8:
            state = TileStateType.eight;
            break;
        }
      }
    }

    return state != before;
  }

  void speculate() {
    switch (state) {
      case TileStateType.predictedBombCorrect:
        state = TileStateType.unsure;
        break;
      case TileStateType.unsure:
        state = TileStateType.notPressed;
        break;
      case TileStateType.notPressed:
        state = TileStateType.predictedBombCorrect;
        break;
      default:
        break;
    }
  }

  void reveal() {
    switch (state) {
      case TileStateType.predictedBombCorrect:
        if (!hasMine) {
          state = TileStateType.predictedBombIncorrect;
        }
        break;
      case TileStateType.unsure:
      case TileStateType.notPressed:
        if (hasMine) {
          state = TileStateType.revealedBomb;
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
