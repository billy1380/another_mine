import 'dart:async';
import 'dart:math';

import 'package:another_mine/ai/guesser.dart';
import 'package:another_mine/model/game_difficulty_type.dart';
import 'package:another_mine/model/game_state_type.dart';
import 'package:another_mine/model/tile_state_type.dart';
import 'package:another_mine/model/tilemodel.dart';
import 'package:another_mine/services/pref.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:main_thread_processor/main_thread_processor.dart';

part 'game_event.dart';
part 'game_state.dart';

final Random r = Random();
const Color defaultBackgroundColour = Color.fromARGB(0xff, 0x2e, 0x34, 0x36);
const String difficultySettingName = "difficulty";
const String autoSolverSettingName = "auto_solver";
const String colourSettingName = "colour";

int random(int scale) {
  return (r.nextDouble() * scale).toInt();
}

class GameBloc extends Bloc<GameEvent, GameState> {
  late Guesser guesser;
  static final Logger _log = Logger("GameBloc");

  GameBloc()
      : super(GameState.initial(
            GameDifficultyType.beginner, defaultBackgroundColour)) {
    on<RevealAll>(_revealAll);
    on<MightPlay>(_mightPlay);
    on<DonePlaying>(_donePlaying);
    on<Speculate>(_speculate);
    on<Probe>(_probe);
    on<ToggleAutoSolver>(_toggleAutoSolver);
    on<NewGame>(_newGame);
    on<AutoSolverNextMove>(_autoSolverNextMove);

    guesser = Guesser(this);
  }

  Future<void> _autoSolverNextMove(
      AutoSolverNextMove event, Emitter<GameState> emit) async {
    if (state.isFinished) {
      if (state.status == GameStateType.won) {
        add(const ToggleAutoSolver());
      } else if (state.status == GameStateType.lost) {
        // wait for some time before starting a new game
        await Future.delayed(const Duration(
          seconds: 2,
        ));

        if (!guesser.pause) {
          add(NewGame(
            difficulty: state.difficulty,
          ));
        }
      }
    } else {
      if (!guesser.pause) {
        Processor.shared.addTask(
            ProcessRunnables()..addRunnable("guesser move", guesser.makeAMove));
      }
    }
  }

  Future<void> _newGame(NewGame event, Emitter<GameState> emit) async {
    GameDifficultyType difficulty = event.difficulty;

    await Pref.service.setString(autoSolverSettingName, difficulty.name);

    String colourValue = Pref.service.getString(colourSettingName) ??
        defaultBackgroundColour.value.toString();
    int colour = int.parse(colourValue);

    emit(GameState.initial(difficulty, Color(colour)).copyWith(
      autoSolverEnabled: state.autoSolverEnabled,
    ));

    if (state.autoSolverEnabled) {
      add(const AutoSolverNextMove());
    }
  }

  Future<void> _toggleAutoSolver(
      ToggleAutoSolver event, Emitter<GameState> emit) async {
    bool status = false;
    try {
      status = Pref.service.getBool(autoSolverSettingName) ?? false;
    } catch (e) {
      _log.warning(
          "Could not get setting $autoSolverSettingName defaulting to false");
    }

    status = !status;

    await Pref.service.setBool(autoSolverSettingName, status);

    emit(state.copyWith(autoSolverEnabled: status));

    if (status) {
      add(const AutoSolverNextMove());
    } else {
      Processor.shared.removeAllTasks();
      stream.drain();
    }
  }

  Future<void> _probe(Probe event, Emitter<GameState> emit) async {
    if (state.isNotFinished) {
      TileModel tile = event.model;

      int area = GameDifficultyType.difficultyArea(state.difficulty);

      if (tile.hasMine && state.start == null) {
        _relocateMine(tile);

        add(Probe(model: event.model));
      } else {
        GameState newState = state;

        if (state.start == null) {
          emit(newState = newState.copyWith(
            start: DateTime.now(),
            status: GameStateType.started,
          ));
        }

        if (tile.probe()) {
          emit(newState = newState.copyWith(
            revealedTiles: state.revealedTiles + 1,
          ));
        }

        if (tile.state == TileStateType.detenateBomb) {
          emit(newState = newState.copyWith(
            end: DateTime.now(),
            status: GameStateType.lost,
          ));

          add(const RevealAll());
        } else if (state.revealedTiles + state.difficulty.mines == area) {
          emit(newState = newState.copyWith(
            end: DateTime.now(),
            status: GameStateType.won,
          ));

          add(const RevealAll());
        } else {
          int marked = 0;

          for (int i = 0; i < tile.neighbours.length; i++) {
            final TileModel? neighbour = tile.neighbours[i];

            if (neighbour != null &&
                neighbour.state == TileStateType.predictedBombCorrect) {
              marked++;
            }
          }

          if (tile.neigbouringMine == marked) {
            for (int i = 0; i < tile.neighbours.length; i++) {
              final TileModel? neighbour = tile.neighbours[i];

              if (neighbour != null &&
                  (neighbour.state == TileStateType.notPressed ||
                      neighbour.state == TileStateType.unsure)) {
                add(Probe(model: neighbour));
              }
            }
          }
        }
      }

      if (state.autoSolverEnabled) {
        add(const AutoSolverNextMove());
      }
    }
  }

  Future<void> _speculate(Speculate event, Emitter<GameState> emit) async {
    if (state.isNotFinished) {
      TileModel tile = event.model..speculate();

      if (tile.state == TileStateType.predictedBombCorrect) {
        emit(state.copyWith(
          minesMarked: state.minesMarked + 1,
        ));
      } else if (tile.state == TileStateType.unsure) {
        emit(state.copyWith(
          minesMarked: state.minesMarked - 1,
        ));
      } else {
        emit(state.copyWith(refresh: state.refresh + 1));
      }

      add(const AutoSolverNextMove());
    }
  }

  Future<void> _revealAll(RevealAll event, Emitter<GameState> emit) async {
    for (TileModel tile in state.tiles) {
      tile.reveal();

      if (tile.state == TileStateType.revealedBomb &&
          state.status == GameStateType.won) {
        tile.state = TileStateType.predictedBombCorrect;
      }
    }

    emit(state.copyWith(refresh: state.refresh + 1));
  }

  Future<void> _mightPlay(MightPlay event, Emitter<GameState> emit) async {
    if (state.status != GameStateType.lost &&
        state.status != GameStateType.won &&
        state.status != GameStateType.thinking) {
      emit(state.copyWith(
        previousStatus: state.status,
        status: GameStateType.thinking,
      ));
    }
  }

  Future<void> _donePlaying(DonePlaying event, Emitter<GameState> emit) async {
    if (state.status == GameStateType.thinking) {
      emit(state.copyWith(
        status: state.previousStatus,
      ));
    }
  }

  void _relocateMine(TileModel tile) {
    tile.hasMine = false;

    for (TileModel t in state.tiles) {
      if (t != tile && !t.hasMine) {
        t.hasMine = true;
        break;
      }
    }

    GameState._updateMineCountAndNeighbours(state.difficulty, state.tiles);
  }
}
