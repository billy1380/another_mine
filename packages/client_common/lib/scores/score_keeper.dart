import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_common/model/game_state_type.dart";
import "package:another_mine_common/model/tile_model.dart";
import "package:another_mine_common/scores/local_score.dart";
import "package:another_mine_common/scores/local_scores.dart";
import "package:another_mine_common/scores/online_board.dart";
import "package:another_mine_common/scores/score_row.dart";
import "package:another_mine_common/scores/score_submitter.dart";
import "package:another_mine_common/scores/score_category.dart";
import "package:another_mine_common/services/pref.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "package:willshex_scores/willshex_scores.dart" as scores;

/// A game the player has just won, before it is given a name and kept.
class WonGame {
  final int seconds;
  final int width;
  final int height;
  final int mines;
  final ScoreCategory category;
  final Solver solver;

  /// The mines as a base64 bitset (one bit a tile, 1 for a mine) and what the
  /// player did, for the recording sent online.
  final String layout;
  final List<List<Object>> events;

  const WonGame({
    required this.seconds,
    required this.width,
    required this.height,
    required this.mines,
    required this.category,
    required this.solver,
    this.layout = "",
    this.events = const [],
  });

  /// The won game in [state], or null if the game was not won. [events] is what
  /// the player did, from the game's recorder.
  static WonGame? from(
    GameState state,
    Pref pref, {
    List<List<Object>> events = const [],
  }) {
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
      layout: _layoutOf(state),
      events: events,
    );
  }

  static String _layoutOf(GameState state) {
    final Uint8List bits = Uint8List((state.tiles.length + 7) ~/ 8);

    for (final TileModel tile in state.tiles) {
      if (tile.hasMine) bits[tile.index >> 3] |= 1 << (tile.index & 7);
    }

    return base64.encode(bits);
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

  final OnlineBoard _online = OnlineBoard();
  late final ScoreSubmitter _submitter = ScoreSubmitter(_pref);

  LocalScores? _local;

  ScoreKeeper(this.path, this._pref);

  bool get isEnabled => path != null;

  @override
  Future<void> onInit() async {
    if (path != null) {
      _local = LocalScores(path!, retained: _pref.scoresRetained);
    }

    // anything that could not be sent last time
    unawaited(_submitter.flush());
  }

  @override
  void onReset() {
    _local = null;
  }

  /// The won game in [state], or null if there is none to keep: the game was
  /// not won, the auto solver played any of it (its times would crowd out the
  /// player's), or this host keeps no scores.
  WonGame? wonGame(GameState state, {List<List<Object>> events = const []}) =>
      isEnabled && !state.solverUsed
      ? WonGame.from(state, _pref, events: events)
      : null;

  /// Sends [game] online if online scores are on and it is one to send, else
  /// does nothing. Never throws.
  Future<void> submitOnline(WonGame game) => _submitter.submit(game);

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

  /// Whether the scores page lists the online scores rather than this
  /// device's.
  bool get showsOnline => _pref.remoteScoresEnabled;

  /// Stops saving and listing scores online.
  Future<void> switchToLocal() =>
      _pref.setBool(Pref.keyRemoteScoresEnabled, false);

  /// The categories the scores page has a tab for: those kept online when it
  /// lists the online scores, else all.
  List<ScoreCategory> get categories => [
    for (final ScoreCategory c in ScoreCategory.values)
      if (!showsOnline || c.isOnline) c,
  ];

  /// The lines of the scores table for [category], best first: the online
  /// scores or this device's, as [showsOnline] says.
  Future<List<ScoreRow>> rows(ScoreCategory category) async => showsOnline
      ? [
          for (final OnlineScore s in await _online.top(category))
            _remember(_row(s)),
        ]
      : [
          for (final LocalScore s in await top(category))
            ScoreRow(
              name: s.name,
              detail: s.board,
              seconds: s.seconds,
              when: s.when,
              local: s,
            ),
        ];

  static final Map<int, ScoreRow> _known = {};

  /// Remembers an online score a host already has, so that its replay does not
  /// ask the server for it again.
  static void know(scores.Score score) {
    final int? id = score.id;

    if (id != null) _known[id] = _row(OnlineBoard.convert(score));
  }

  /// The online score with [id], or null if it is not found. One already seen
  /// is not fetched again.
  Future<ScoreRow?> onlineScore(int id) async {
    final ScoreRow? seen = _known[id];

    if (seen != null) return seen;

    final OnlineScore? score = await _online.find(id);

    return score == null ? null : _row(score);
  }

  static ScoreRow _remember(ScoreRow row) {
    if (row.id != null) _known[row.id!] = row;

    return row;
  }

  static ScoreRow _row(OnlineScore s) => ScoreRow(
    id: s.id,
    name: s.name,
    detail: s.board,
    country: s.country,
    flag: s.flag,
    service: s.service,
    serviceName: s.serviceName,
    seconds: s.seconds,
    when: s.when,
    recording: s.recording,
  );

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
