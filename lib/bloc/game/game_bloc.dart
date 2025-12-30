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
const int lostGameAutoSolverPause = 2;

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
    on<PauseGame>(_pauseGame);
    on<ResumeGame>(_resumeGame);

    guesser = Guesser(this);
  }

  Future<void> _pauseAutoSolver(
      PauseAutoSolver event, Emitter<GameState> emit) async {
    if (state.autoSolverEnabled) {
      Processor.shared.pause();

      final DateTime now = DateTime.now();
      Duration accumulated = state.accumulatedDuration;
      if (state.lastActiveTime != null) {
        accumulated += now.difference(state.lastActiveTime!);
      }

      emit(state.copyWith(
        autoSolverPaused: true,
        accumulatedDuration: accumulated,
        clearLastActiveTime: true,
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

      final DateTime now = DateTime.now();
      emit(state.copyWith(
        autoSolverPaused: false,
        lastActiveTime: state.isNotFinished && state.start != null ? now : null,
      ));
    }
  }

  Future<void> _autoSolverNextMove(
      AutoSolverNextMove event, Emitter<GameState> emit) async {
    if (state.isFinished) {
      if (state.status == GameStateType.won) {
        add(const ToggleAutoSolver());
      } else if (state.status == GameStateType.lost) {
        await Future.delayed(const Duration(
          seconds: lostGameAutoSolverPause,
        ));

        if (!state.autoSolverPaused) {
          add(NewGame(
            difficulty: state.difficulty,
          ));
        }
      }
    } else {
      if (state.autoSolverEnabled && !state.autoSolverPaused) {
        Processor.shared.removeAllTasks();

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
    final DateTime now = DateTime.now();

    if (state.isNotFinished) {
      if (_handleFirstMoveProtection(event)) return;

      GameState runningState = _ensureGameStarted(state, now);

      GameState finalState = _processFloodFill(runningState, event.model, now);

      emit(finalState);

      if (state.autoSolverEnabled) {
        add(const AutoSolverNextMove());
      }
    }
  }

  bool _handleFirstMoveProtection(Probe event) {
    if (event.model.hasMine && state.start == null) {
      _relocateMine(event.model);
      add(Probe(model: event.model));
      return true;
    }
    return false;
  }

  GameState _ensureGameStarted(GameState currentState, DateTime now) {
    if (currentState.start == null) {
      return currentState.copyWith(
        start: now,
        lastActiveTime: now,
        status: GameStateType.started,
      );
    }
    return currentState;
  }

  GameState _processFloodFill(
      GameState currentState, TileModel startTile, DateTime now) {
    int newRevealedCount = currentState.revealedTiles;
    GameStateType newStatus = currentState.status;
    DateTime? newEnd = currentState.end;
    Duration newAccumulated = currentState.accumulatedDuration;
    bool newClearLastActive = false;

    List<TileModel> queue = [startTile];
    Set<int> processed = {};

    while (queue.isNotEmpty) {
      TileModel tile = queue.removeAt(0);

      if (processed.contains(tile.index)) continue;
      processed.add(tile.index);

      if (tile.probe()) {
        newRevealedCount++;
      }

      if (tile.state == TileStateType.detenateBomb) {
        newEnd = now;
        newAccumulated += now.difference(currentState.lastActiveTime ?? now);
        newClearLastActive = true;
        newStatus = GameStateType.lost;
        _log.info("Game Lost");
        add(const RevealAll());
        break;
      } else if (newRevealedCount + currentState.difficulty.mines ==
          currentState.difficulty.area) {
        newEnd = now;
        newAccumulated += now.difference(currentState.lastActiveTime ?? now);
        newClearLastActive = true;
        newStatus = GameStateType.won;
        _log.info("Game Won at $newEnd");
        add(const RevealAll());
        break;
      } else {
        int marked = 0;
        for (var neighbour in tile.neighbours) {
          if (neighbour != null &&
              neighbour.state == TileStateType.predictedBombCorrect) {
            marked++;
          }
        }

        if (tile.neigbouringMine == marked) {
          for (var neighbour in tile.neighbours) {
            if (neighbour != null &&
                (neighbour.state == TileStateType.notPressed ||
                    neighbour.state == TileStateType.unsure)) {
              if (!processed.contains(neighbour.index)) {
                queue.add(neighbour);
              }
            }
          }
        }
      }
    }

    return currentState.copyWith(
      revealedTiles: newRevealedCount,
      status: newStatus,
      end: newEnd,
      accumulatedDuration: newAccumulated,
      clearLastActiveTime: newClearLastActive,
      lastInteractedIndex: startTile.index,
    );
  }

  Future<void> _speculate(Speculate event, Emitter<GameState> emit) async {
    if (state.isNotFinished) {
      TileModel tile = event.model..speculate();

      if (tile.state == TileStateType.predictedBombCorrect) {
        emit(state.copyWith(
          minesMarked: state.minesMarked + 1,
          lastInteractedIndex: tile.index,
        ));
      } else if (tile.state == TileStateType.unsure) {
        emit(state.copyWith(
          minesMarked: state.minesMarked - 1,
          lastInteractedIndex: tile.index,
        ));
      } else {
        emit(state.copyWith(
          refresh: state.refresh + 1,
          lastInteractedIndex: tile.index,
        ));
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

  Future<void> _pauseGame(PauseGame event, Emitter<GameState> emit) async {
    final DateTime now = DateTime.now();

    if (state.autoSolverEnabled) {
      Processor.shared.pause();
    }

    Duration accumulated = state.accumulatedDuration;
    if (state.lastActiveTime != null) {
      accumulated += now.difference(state.lastActiveTime!);
    }

    emit(state.copyWith(
      accumulatedDuration: accumulated,
      clearLastActiveTime: true,
      autoSolverPaused: true,
    ));
  }

  Future<void> _resumeGame(ResumeGame event, Emitter<GameState> emit) async {
    final DateTime now = DateTime.now();

    if (state.autoSolverEnabled) {
      Processor.shared.resume();
    }

    emit(state.copyWith(
      lastActiveTime: state.isNotFinished && state.start != null ? now : null,
      autoSolverPaused: false,
    ));
  }
}
