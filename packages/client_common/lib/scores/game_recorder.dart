import "package:another_mine_common/bloc/game/game_bloc.dart";

/// Records what the player does in a game, as `[ms, code, argument]` events, so
/// it can be replayed: `p` reveals a tile and `f` flags it (the argument is the
/// tile index), `pause` and `resume`, and `prob` and `focus` when probability
/// mode or focus mode is turned on (1) or off (0). `ms` counts from the first
/// event.
///
/// A game the auto solver played any part of is not recorded: it is never kept.
class GameRecorder {
  final DateTime Function() _now;
  final List<List<Object>> _events = [];
  DateTime? _first;

  GameRecorder({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// The events so far.
  List<List<Object>> get events => List.unmodifiable(_events);

  void reset() {
    _events.clear();
    _first = null;
  }

  /// Notes [event], which is about to be handled with the game in [state].
  void record(GameEvent event, GameState state) {
    if (event is NewGame) return reset();
    if (state.isFinished || state.autoSolverEnabled || state.solverUsed) return;

    switch (event) {
      // the first move onto a mine moves it and plays again, so it is not twice
      case Probe(:final model) when !(model.hasMine && state.start == null):
        _add("p", model.index);
      case Speculate(:final model):
        _add("f", model.index);
      case PauseGame():
        _add("pause");
      case ResumeGame():
        _add("resume");
      case ToggleProbabilities():
        _add("prob", state.showProbability ? 0 : 1);
      case ToggleFocusMode():
        _add("focus", state.isFocusMode ? 0 : 1);
      default:
    }
  }

  void _add(String code, [int? argument]) {
    final DateTime now = _now();
    _first ??= now;
    _events.add([now.difference(_first!).inMilliseconds, code, ?argument]);
  }
}
