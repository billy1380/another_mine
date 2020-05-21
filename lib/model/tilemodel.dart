import 'package:another_mine/model/tilestate.dart';
import 'package:flutter/material.dart';

class TileModel {
  TileState state;
  bool hasMine;
  Color colour;
  int index;
  // GameDifficulty difficulty;
  final List<TileModel> neighbours = List<TileModel>(8);
  int neigbouringMine;

  void setNeightbourAt(int index, TileModel model) {
    int i = index;
    if (i > 4) {
      i--;
    }
    neighbours[i] = model;
  }

  bool probe() {
    TileState before = state;

    if (state != TileState.PredictedBombCorrect) {
      if (hasMine) {
        state = TileState.DetenateBomb;
      } else {
        state = TileState.RevealedSafe;

        switch (neigbouringMine) {
          case 1:
            state = TileState.One;
            break;
          case 2:
            state = TileState.Two;
            break;
          case 3:
            state = TileState.Three;
            break;
          case 4:
            state = TileState.Four;
            break;
          case 5:
            state = TileState.Five;
            break;
          case 6:
            state = TileState.Six;
            break;
          case 7:
            state = TileState.Seven;
            break;
          case 8:
            state = TileState.Eight;
            break;
        }
      }
    }

    return state != before;
  }

  void speculate() {
    switch (state) {
      case TileState.PredictedBombCorrect:
        state = TileState.Unsure;
        break;
      case TileState.Unsure:
        state = TileState.NotPressed;
        break;
      case TileState.NotPressed:
        state = TileState.PredictedBombCorrect;
        break;
      default:
        break;
    }
  }

  void reveal() {
    switch (state) {
      case TileState.PredictedBombCorrect:
        if (!hasMine) {
          state = TileState.PredictedBombIncorrect;
        }
        break;
      case TileState.Unsure:
      case TileState.NotPressed:
        if (hasMine) {
          state = TileState.RevealedBomb;
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
