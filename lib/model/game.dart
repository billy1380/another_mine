import 'dart:math';

import 'package:another_mine/model/gamedifficulty.dart';
import 'package:another_mine/model/gamestate.dart';
import 'package:another_mine/model/tilemodel.dart';
import 'package:another_mine/model/tilestate.dart';
import 'package:flutter/material.dart';

const Color defaultBackgroundColour = Color.fromARGB(0xff, 0x2e, 0x34, 0x36);

class Game extends ChangeNotifier {
  static final Random r = Random();

  GameDifficulty _difficulty = GameDifficulty.beginner;
  GameState _state = GameState.notStarted;
  final List<TileModel> _tiles = <TileModel>[];
  DateTime? _start, _end;
  GameState _previousState = GameState.notStarted;
  int _minesMarked = 0;
  int _revealedTiles = 0;
  Color colour = defaultBackgroundColour;

  void start() {
    _start = null;
    _end = null;
    _state = GameState.notStarted;
    _minesMarked = 0;
    _revealedTiles = 0;

    _createTiles();
    _createMineMap();

    notifyListeners();
  }

  void _createTiles() {
    int tileSize = _tiles.length;
    int difference = tileSize - GameDifficulty.difficultyArea(_difficulty);
    if (difference > 0) {
      for (int i = 0; i < difference; i++) {
        _tiles.removeAt(_tiles.length - 1);
      }
    } else if (difference < 0) {
      difference = 0 - difference;

      for (int i = 0; i < difference; i++) {
        _tiles.add(TileModel());
      }
    }
  }

  void _createMineMap() {
    Color c;
    int tileCount = GameDifficulty.difficultyArea(_difficulty);
    for (int i = 0; i < tileCount; i++) {
      c = Color.fromARGB(
          76 + (r.nextInt(179)), colour.red, colour.green, colour.blue);
      _tiles[i]
            ..hasMine = false
            ..colour = c
            // ..difficulty = difficulty
            ..index = i
            ..state = TileState.notPressed
            ..clearNeighbours()
          //					.state(TileState.values()[(int) (Math.random()
          //							* TileState.values().length)])
          ;
    }

    int k, allocatedMines = 0;
    bool newPosition;
    List<int> mineLocations = List<int>.filled(tileCount, 0);

    while (allocatedMines < difficulty.mines) {
      newPosition = true;
      mineLocations[allocatedMines] = r.nextInt(tileCount);

      for (k = 0; k < allocatedMines; k++) {
        if (mineLocations[k] == mineLocations[allocatedMines]) {
          newPosition = false;
          break;
        }
      }

      if (newPosition) {
        _tiles[mineLocations[allocatedMines]].hasMine = true;
        allocatedMines++;
      }
    }

    _updateMineCountAndNeighbours();
  }

  void mightPlay() {
    if (state != GameState.lost && state != GameState.won) {
      _previousState = _state;
      _state = GameState.thinking;
    }
  }

  void donePlay() {
    if (state == GameState.thinking) {
      _state = _previousState;
    }
  }

  bool isCurrent(int x, int y) {
    return x == 0 && y == 0;
  }

  bool outOfBounds(int x, int y) {
    return x < 0 || y < 0 || x >= difficulty.width || y >= difficulty.height;
  }

  void _updateMineCountAndNeighbours() {
    int index, nIndex, count;
    for (int j = 0; j < difficulty.height; j++) {
      for (int i = 0; i < difficulty.width; i++) {
        count = 0;
        index = (j * difficulty.width) + i;
        for (int nj = -1; nj <= 1; nj++) {
          for (int ni = -1; ni <= 1; ni++) {
            if (isCurrent(ni, nj) || outOfBounds(i + ni, j + nj)) continue;
            nIndex = ((j + nj) * difficulty.width) + (i + ni);
            if (_tiles[nIndex].hasMine) {
              count++;
            }

            _tiles[index]
                .setNeightbourAt(((nj + 1) * 3) + (ni + 1), _tiles[nIndex]);
          }
        }

        _tiles[index].neigbouringMine = count;
      }
    }
  }

  void probe(TileModel? tile) {
    if (tile != null) {
      int area = GameDifficulty.difficultyArea(_difficulty);

      if (tile.hasMine && _start == null) {
        _relocateMine(tile);
        probe(tile);
      } else {
        if (_start == null) {
          _start = DateTime.now();
          _state = GameState.started;
        }

        if (tile.probe()) {
          _revealedTiles++;
        }

        if (tile.state == TileState.detenateBomb) {
          _state = GameState.lost;
          _end = DateTime.now();
          _revealAll();
        } else if (_revealedTiles + difficulty.mines == area) {
          _state = GameState.won;
          _end = DateTime.now();
          _revealAll();
        } else {
          int marked = 0;
          for (int i = 0; i < tile.neighbours.length; i++) {
            final TileModel? neighbour = tile.neighbours[i];

            if (neighbour != null &&
                neighbour.state == TileState.predictedBombCorrect) {
              marked++;
            }
          }

          if (tile.neigbouringMine == marked) {
            for (int i = 0; i < tile.neighbours.length; i++) {
              final TileModel? neighbour = tile.neighbours[i];
              if (neighbour != null &&
                  (neighbour.state == TileState.notPressed ||
                      neighbour.state == TileState.unsure)) {
                probe(neighbour);
              }
            }
          }
        }
      }

      notifyListeners();
    }
  }

  void _revealAll() {
    for (TileModel tile in _tiles) {
      tile.reveal();

      if (tile.state == TileState.revealedBomb && _state == GameState.won) {
        tile.state = TileState.predictedBombCorrect;
      }
    }
  }

  set difficulty(GameDifficulty value) {
    _difficulty = GameDifficulty.clone(value);
    start();
  }

  GameDifficulty get difficulty {
    return _difficulty;
  }

  GameState get state {
    return _state;
  }

  int get minesMarked {
    return _minesMarked;
  }

  int get seconds {
    return _start == null
        ? 0
        : ((_end == null
                    ? DateTime.now().millisecondsSinceEpoch -
                        _start!.millisecondsSinceEpoch
                    : _end!.millisecondsSinceEpoch -
                        _start!.millisecondsSinceEpoch) *
                .001)
            .toInt();
  }

  List<TileModel> get tiles {
    return List.unmodifiable(_tiles);
  }

  TileModel? tileAt(int x, int y) {
    TileModel? tile;
    if (state != GameState.lost && state != GameState.won) {
      tile = _tiles[(y * difficulty.width) + x];
    }

    return tile;
  }

  bool probeAt(int x, int y) {
    final TileModel? tile = tileAt(x, y);

    probe(tile);

    return tile != null;
  }

  bool speculateAt(int x, int y) {
    final TileModel? tile = tileAt(x, y);

    speculate(tile);

    return tile != null;
  }

  void speculate(TileModel? tile) {
    if (tile != null) {
      tile.speculate();

      if (tile.state == TileState.predictedBombCorrect) {
        _minesMarked++;
      } else if (tile.state == TileState.unsure) {
        _minesMarked--;
      }

      notifyListeners();
    }
  }

  void _relocateMine(TileModel tile) {
    tile.hasMine = false;

    for (TileModel t in _tiles) {
      if (t != tile && !t.hasMine) {
        t.hasMine = true;
        break;
      }
    }

    _updateMineCountAndNeighbours();
  }

  bool get isFinished {
    return _state == GameState.won || _state == GameState.lost;
  }
}
