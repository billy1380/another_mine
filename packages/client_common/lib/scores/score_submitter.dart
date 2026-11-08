import "dart:convert";

import "package:another_mine_common/scores/local_score.dart";
import "package:another_mine_common/scores/online_config.dart";
import "package:another_mine_common/scores/score_category.dart";
import "package:another_mine_common/scores/score_keeper.dart";
import "package:another_mine_common/services/pref.dart";
import "package:archive/archive.dart";
import "package:logging/logging.dart";
import "package:willshex_scores/willshex_scores.dart" as scores;
import "package:willshex_space_cloud/data_type/session.dart";
import "package:willshex_space_cloud/willshex_space_cloud.dart" as cloud;

/// Sends the games that are won to the online scores, and keeps those that
/// could not be sent in [Pref] to try again on the next launch or win.
///
/// Never throws and never holds the game up: a failed send is queued, and given
/// up on after [maxAttempts].
class ScoreSubmitter {
  static final Logger _log = Logger("ScoreSubmitter");

  static const String keyPending = "pendingOnlineScores";
  static const int maxAttempts = 5;
  static const int maxQueued = 20;

  /// The fastest time in seconds that is believed for a board; a faster one is
  /// not sent.
  static const Map<ScoreCategory, int> minimumSeconds = {
    ScoreCategory.beginner: 1,
    ScoreCategory.intermediate: 3,
    ScoreCategory.expert: 10,
    ScoreCategory.medium: 3,
    ScoreCategory.hard: 5,
  };

  final Pref _pref;
  final scores.CoreServiceClient _scores;
  final cloud.CoreServiceClient _cloud;
  bool _flushing = false;

  ScoreSubmitter(
    this._pref, {
    scores.CoreServiceClient? scoresClient,
    cloud.CoreServiceClient? cloudClient,
  }) : _scores = scoresClient ?? scores.CoreServiceClient(),
       _cloud = cloudClient ?? cloud.CoreServiceClient();

  /// Whether [game] is one to send: online scores are on, it is a human game
  /// of a category that is kept online, and not faster than believable.
  bool shouldSend(WonGame game) =>
      _pref.remoteScoresEnabled &&
      _pref.playerName.isNotEmpty &&
      game.category.isOnline &&
      game.solver == Solver.human &&
      game.seconds >= (minimumSeconds[game.category] ?? 0);

  /// Queues [game] if it is one to send and tries to send what is queued.
  Future<void> submit(WonGame game) async {
    if (!shouldSend(game)) return;

    final List<Map<String, dynamic>> pending = _pending()
      ..add({
        "category": game.category.label,
        "seconds": game.seconds,
        "board": game.toScore(_pref.playerName, DateTime.now()).board,
        "when": DateTime.now().millisecondsSinceEpoch,
        "data": encode(game),
        "name": _pref.playerName,
        "service": _pref.playerService.name,
        "country": cloud.fromCountryToString(_pref.defaultCountry),
        "attempts": 0,
      });

    await _save(pending.length > maxQueued ? pending.sublist(1) : pending);
    await flush();
  }

  /// Tries to send everything queued, once each.
  Future<void> flush() async {
    if (_flushing || !_pref.remoteScoresEnabled) return;

    _flushing = true;

    try {
      final List<Map<String, dynamic>> left = [];

      for (final Map<String, dynamic> item in _pending()) {
        try {
          await _send(item);
        } catch (e) {
          _log.info("Could not send a score: $e");
          item["attempts"] = (item["attempts"] as int) + 1;
          if (item["attempts"] < maxAttempts) left.add(item);
        }
      }

      await _save(left);
    } finally {
      _flushing = false;
    }
  }

  Future<void> _send(Map<String, dynamic> item) async {
    final Session session = Session(accessCode: OnlineConfig.publisherKey);
    final cloud.User player = cloud.User(
      name: item["name"] as String,
      type: cloud.UserTypeType.values.byName(item["service"] as String),
      country: cloud.fromStringToCountry(item["country"] as String),
    );
    final int? id = OnlineConfig.categoryId(
      ScoreCategory.values.firstWhere((c) => c.label == item["category"]),
    );

    // SubmitScore refuses a player the server does not know; AddUser fails
    // for one it does, which is fine
    try {
      await _cloud.addUser(
        cloud.AddUserRequest(session: session, user: player),
      );
    } catch (_) {}

    final scores.SubmitScoreResponse response = await _scores.submitScore(
      scores.SubmitScoreRequest(
        session: session,
        score: scores.Score(
          category: scores.Category(id: id),
          player: cloud.User(name: player.name, type: player.type),
          value: item["seconds"] as int,
          description: item["board"] as String,
          when: DateTime.fromMillisecondsSinceEpoch(item["when"] as int),
          attempt: 1,
          additionalData: item["data"] as String,
        ),
      ),
    );

    if (response.error != null) throw StateError("${response.error?.message}");
  }

  /// The game as recorded for the admin and for replay, gzip then base64, as
  /// Delta-V sends its data.
  static String encode(WonGame game) => base64.encode(
    GZipEncoder().encode(
      utf8.encode(
        jsonEncode({
          "game": "anothermine",
          "version": 2,
          "difficulty": game.category.label.toLowerCase(),
          "width": game.width,
          "height": game.height,
          "mines": game.mines,
          "solver": game.solver.name,
          "layout": game.layout,
          "events": game.events,
        }),
      ),
    ),
  );

  List<Map<String, dynamic>> _pending() {
    final String? raw = _pref.getString(keyPending);

    if (raw == null || raw.isEmpty) return [];

    try {
      return [
        for (final dynamic e in jsonDecode(raw) as List)
          e as Map<String, dynamic>,
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<Map<String, dynamic>> pending) =>
      _pref.setString(keyPending, pending.isEmpty ? null : jsonEncode(pending));
}
