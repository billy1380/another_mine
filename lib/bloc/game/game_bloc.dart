import "dart:math";

import "package:another_mine/ai/game_move.dart";
import "package:another_mine/ai/guesser.dart";
import "package:another_mine/ai/interaction_type.dart";
import "package:another_mine/ai/probability_guesser.dart";
import "package:another_mine/ai/simple_guesser.dart";
import "package:another_mine/logic/game_builder.dart";
import "package:another_mine/logic/probability_calculator.dart";
import "package:another_mine/logic/random_game_builder.dart";
import "package:another_mine/model/auto_solver_type.dart";
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
const double gameTopBarHeight = 100;
const double mineDim = 40;
const int defaultLostGameAutoSolverPause = 2;
Random defaultRandom = Random();

class GameBloc extends Bloc<GameEvent, GameState> {
  static final Logger _log = Logger("GameBloc");

  late Guesser guesser;
  final Processor processor;
  final int lostGamePause;
  final GameBuilder gameBuilder;

  GameBloc({
    required this.processor,
    GameBuilder? gameBuilder,
    this.lostGamePause = defaultLostGameAutoSolverPause,
  })  : gameBuilder = gameBuilder ?? RandomGameBuilder(),
        super(GameState.initial(
          GameDifficulty.beginner,
          defaultBackgroundColour,
          gameBuilder ?? RandomGameBuilder(),
        )) {
    on<RevealAll>(_revealAll);
    on<MightPlay>(_mightPlay);
    on<DonePlaying>(_donePlaying);
    on<Speculate>(_speculate);
    on<Probe>(_probe);
    on<ToggleAutoSolver>(_toggleAutoSolver);
    on<NewGame>(_newGame);
    on<AutoSolverNextMove>(_autoSolverNextMove);
    on<ToggleProbabilities>(_toggleProbabilities);
    on<ToggleFocusMode>(_toggleFocusMode);
    on<PauseAutoSolver>(_pauseAutoSolver);
    on<ResumeAutoSolver>(_resumeAutoSolver);
    on<PauseGame>(_pauseGame);
    on<ResumeGame>(_resumeGame);

    guesser = Pref.service.autoSolverType.newGuesser(defaultRandom);
  }

  Future<void> _pauseAutoSolver(
      PauseAutoSolver event, Emitter<GameState> emit) async {
    if (state.autoSolverEnabled) {
      processor.pause();

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
        processor.resume();
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
        emit(state.copyWith(autoSolverEnabled: false));
        processor.removeAllTasks();
      } else if (state.status == GameStateType.lost) {
        if (lostGamePause > 0) {
          await Future.delayed(
            Duration(
              seconds: lostGamePause,
            ),
          );
        }

        if (!state.autoSolverPaused) {
          add(NewGame(
            difficulty: state.difficulty,
          ));
        }
      }
    } else {
      if (state.autoSolverEnabled && !state.autoSolverPaused) {
        processor.removeAllTasks();

        _log.info("Auto solver is managing next move");

        if (Pref.service.autoSolverType == AutoSolverType.probability) {
          if (guesser is! ProbabilityGuesser) {
            guesser = ProbabilityGuesser(defaultRandom);
          }
        } else {
          if (guesser is ProbabilityGuesser) {
            guesser = SimpleGuesser(defaultRandom);
          }
        }

        processor.addTask(ProcessRunnables.single("guesser move", () {
          if (isClosed) return;
          final GameMove move = guesser.makeAMove(
            state.tiles,
            state.difficulty,
            state.status,
          );
          if (isClosed) return;
          switch (move.type) {
            case InteractionType.probe:
              final tile = state.tileAt(move.x, move.y);
              if (tile != null) add(Probe(model: tile));
              break;
            case InteractionType.speculate:
              final tile = state.tileAt(move.x, move.y);
              if (tile != null) add(Speculate(model: tile));
              break;
            case InteractionType.none:
              break;
          }
        }));
      }
    }
  }

  Future<void> _newGame(NewGame event, Emitter<GameState> emit) async {
    GameDifficulty difficulty = event.difficulty;
    _log.info("Starting new game: ${difficulty.name}");

    await Pref.service.setInt("width", difficulty.width);
    await Pref.service.setInt("height", difficulty.height);
    await Pref.service.setInt("mines", difficulty.mines);

    int colourValue =
        Pref.service.customBgColor ?? defaultBackgroundColour.toARGB32();

    emit(GameState.initial(
      difficulty,
      Color(colourValue),
      gameBuilder,
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

    await Pref.service.setBool(Pref.keyAutoSolverSettingName, status);

    emit(state.copyWith(
      autoSolverEnabled: status,
      isFocusMode: status ? false : state.isFocusMode,
    ));

    if (status) {
      add(const AutoSolverNextMove());
    } else {
      processor.removeAllTasks();
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

    final GameState updatedState = currentState.copyWith(
      revealedTiles: newRevealedCount,
      status: newStatus,
      end: newEnd,
      accumulatedDuration: newAccumulated,
      clearLastActiveTime: newClearLastActive,
      lastInteractedIndex: startTile.index,
    );

    return updatedState.copyWith(
      mineProbabilities: _calculateProbabilities(updatedState),
    );
  }

  Future<void> _speculate(Speculate event, Emitter<GameState> emit) async {
    if (state.isNotFinished) {
      TileModel tile = event.model..speculate();

      if (tile.state == TileStateType.predictedBombCorrect) {
        final updated = state.copyWith(
          minesMarked: state.minesMarked + 1,
          lastInteractedIndex: tile.index,
        );
        emit(updated.copyWith(
          mineProbabilities: _calculateProbabilities(updated),
        ));
      } else if (tile.state == TileStateType.unsure) {
        final updated = state.copyWith(
          minesMarked: state.minesMarked - 1,
          lastInteractedIndex: tile.index,
        );
        emit(updated.copyWith(
          mineProbabilities: _calculateProbabilities(updated),
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

    processor.removeAllTasks();

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

    GameBuilder.updateMineCountAndNeighbours(state.difficulty, state.tiles);
  }

  Future<void> _pauseGame(PauseGame event, Emitter<GameState> emit) async {
    final DateTime now = DateTime.now();

    if (state.autoSolverEnabled) {
      processor.pause();
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
      processor.resume();
    }

    emit(state.copyWith(
      lastActiveTime: state.isNotFinished && state.start != null ? now : null,
      autoSolverPaused: false,
    ));
  }

  List<double> _calculateProbabilities(GameState state) {
    return ProbabilityCalculator.calculate(
      state.tiles,
      state.difficulty,
      state.status,
    );
  }

  void _toggleProbabilities(
    ToggleProbabilities event,
    Emitter<GameState> emit,
  ) {
    emit(state.copyWith(showProbability: !state.showProbability));
  }

  void _toggleFocusMode(
    ToggleFocusMode event,
    Emitter<GameState> emit,
  ) {
    if (state.autoSolverEnabled) return;
    emit(state.copyWith(isFocusMode: !state.isFocusMode));
  }
}

extension AutoSolverTypeEx on AutoSolverType {
  Guesser newGuesser(Random random) => switch (this) {
        AutoSolverType.simple => SimpleGuesser(random),
        AutoSolverType.probability => ProbabilityGuesser(random),
      };
}
