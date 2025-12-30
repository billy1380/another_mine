import "dart:async";

import "package:another_mine/ai/guesser.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/model/tile_model.dart";
import "package:another_mine/model/tile_state_type.dart";
import "package:another_mine/services/pref.dart";
import "package:bloc/bloc.dart";
import "package:equatable/equatable.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:main_thread_processor/main_thread_processor.dart";

part "game_event.dart";
part "game_state.dart";

const Color defaultBackgroundColour = Color.fromARGB(0xff, 0x2e, 0x34, 0x36);
const String autoSolverSettingName = "auto_solver";
const String colourSettingName = "colour";
const double gameTopBarHeight = 100;
const double mineDim = 40;

class GameBloc extends Bloc<GameEvent, GameState> {
  static final Logger _log = Logger("GameBloc");

  late Guesser guesser;

  GameBloc()
      : super(GameState.initial(
            GameDifficulty.beginner, defaultBackgroundColour)) {
    on<RevealAll>(_revealAll);
    on<MightPlay>(_mightPlay);
    on<DonePlaying>(_donePlaying);
    on<Speculate>(_speculate);
    on<Probe>(_probe);
    on<ToggleAutoSolver>(_toggleAutoSolver);
    on<NewGame>(_newGame);
    on<AutoSolverNextMove>(_autoSolverNextMove);
    on<PauseAutoSolver>(_pauseAutoSolver);
    on<ResumeAutoSolver>(_resumeAutoSolver);

    guesser = Guesser(this);
  }

  Future<void> _pauseAutoSolver(
      PauseAutoSolver event, Emitter<GameState> emit) async {
    if (state.autoSolverEnabled) {
      Processor.shared.pause();
      emit(state.copyWith(
        autoSolverPaused: true,
      ));
    }
  }

  Future<void> _resumeAutoSolver(
      ResumeAutoSolver event, Emitter<GameState> emit) async {
    if (state.autoSolverEnabled) {
      if (state.isFinished) {
        add(NewGame(difficulty: state.difficulty));
      } else {
        Processor.shared.resume();
      }

      emit(state.copyWith(
        autoSolverPaused: false,
      ));
    }
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

        if (!state.autoSolverPaused) {
          add(NewGame(
            difficulty: state.difficulty,
          ));
        }
      }
    } else {
      if (!state.autoSolverPaused) {
        _log.info("Auto solver is managing next move");
        Processor.shared.addTask(
            ProcessRunnables.single("guesser move", guesser.makeAMove));
      }
    }
  }

  Future<void> _newGame(NewGame event, Emitter<GameState> emit) async {
    GameDifficulty difficulty = event.difficulty;
    _log.info("Starting new game: ${difficulty.name}");

    await Pref.service.setInt("width", difficulty.width);
    await Pref.service.setInt("height", difficulty.height);
    await Pref.service.setInt("mines", difficulty.mines);

    String colourValue = Pref.service.getString(colourSettingName) ??
        defaultBackgroundColour.toARGB32().toString();
    int colour = int.parse(colourValue);

    emit(GameState.initial(
      difficulty,
      Color(colour),
    ).copyWith(
      autoSolverEnabled: state.autoSolverEnabled,
    ));

    Size size = Size(
      difficulty.width * mineDim,
      difficulty.height * mineDim,
    );

    emit(state.copyWith(gameSize: size));

    if (state.autoSolverEnabled) {
      add(const AutoSolverNextMove());
    }
  }

  Future<void> _toggleAutoSolver(
      ToggleAutoSolver event, Emitter<GameState> emit) async {
    bool status = !state.autoSolverEnabled;
    _log.info("Toggling auto solver: $status");

    await Pref.service.setBool(autoSolverSettingName, status);

    emit(state.copyWith(autoSolverEnabled: status));

    if (status) {
      add(const AutoSolverNextMove());
    } else {
      Processor.shared.removeAllTasks();
    }
  }

  Future<void> _probe(Probe event, Emitter<GameState> emit) async {
    if (state.isNotFinished) {
      TileModel tile = event.model;

      int area = state.difficulty.area;

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
          _log.info("Game Lost");

          add(const RevealAll());
        } else if (state.revealedTiles + state.difficulty.mines == area) {
          emit(newState = newState.copyWith(
            end: DateTime.now(),
            status: GameStateType.won,
          ));
          _log.info("Game Won");

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

      if (state.autoSolverEnabled) {
        add(const AutoSolverNextMove());
      }
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

    Processor.shared.removeAllTasks();

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
