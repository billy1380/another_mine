import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_common/model/game_state_type.dart";
import "package:another_mine_common/scores/local_score.dart";
import "package:another_mine_common/scores/local_scores.dart";
import "package:another_mine_common/scores/score_category.dart";
import "package:another_mine_common/services/pref.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";

/// A game the player has just won, before it is given a name and kept.
class WonGame {
  final int seconds;
  final int width;
  final int height;
  final int mines;
  final ScoreCategory category;
  final Solver solver;

  const WonGame({
    required this.seconds,
    required this.width,
    required this.height,
    required this.mines,
    required this.category,
    required this.solver,
  });

  /// The won game in [state], or null if the game was not won.
  static WonGame? from(GameState state, Pref pref) {
    if (state.status != GameStateType.won) return null;

    return WonGame(
      seconds: state.seconds,
      width: state.difficulty.width,
      height: state.difficulty.height,
      mines: state.difficulty.mines,
      category: ScoreCategory.forDifficulty(state.difficulty),
      solver: !state.solverUsed
          ? Solver.human
          : pref.autoSolverType.name == Solver.probability.name
          ? Solver.probability
          : Solver.simple,
    );
  }

  LocalScore toScore(String name, DateTime when) => LocalScore(
    name: name,
    seconds: seconds,
    category: category,
    width: width,
    height: height,
    mines: mines,
    solver: solver,
    when: when,
  );
}

/// Keeps the scores of the games that are won: asks the local store where a
/// win would place, and keeps it once it has a name.
class ScoreKeeper extends BasicService {
  /// Where the local scores are stored, or null if this host does not keep
  /// them.
  final String? path;
  final Pref _pref;

  LocalScores? _local;

  ScoreKeeper(this.path, this._pref);

  bool get isEnabled => path != null;

  @override
  Future<void> onInit() async {
    if (path != null) {
      _local = LocalScores(path!, retained: _pref.scoresRetained);
    }
  }

  @override
  void onReset() {
    _local = null;
  }

  /// The won game in [state], or null if there is none to keep: the game was
  /// not won, the auto solver played any of it (its times would crowd out the
  /// player's), or this host keeps no scores.
  WonGame? wonGame(GameState state) =>
      isEnabled && !state.solverUsed ? WonGame.from(state, _pref) : null;

  /// Where [game] would place, or null if it would not be kept.
  Future<int?> rankOf(WonGame game) async =>
      _local?.rankOf(game.category, game.seconds);

  /// Keeps [game] under [name], returning its place or null if it was not good
  /// enough. The name is remembered for the next win.
  Future<int?> keep(WonGame game, String name, {DateTime? when}) async {
    final String trimmed = name.trim();

    await _pref.setString(Pref.keyPlayerName, trimmed);

    return _local?.add(game.toScore(trimmed, when ?? DateTime.now()));
  }

  /// The best scores of [category], best first.
  Future<List<LocalScore>> top(ScoreCategory category) async =>
      _local?.top(category) ?? const [];

  /// Forgets [score], one that [top] returned.
  Future<void> remove(LocalScore score) async => _local?.remove(score);

  /// Forgets every local score of [category].
  Future<void> clearCategory(ScoreCategory category) async =>
      _local?.clearCategory(category);

  /// Forgets every local score.
  Future<void> clear() async => _local?.clear();
}
