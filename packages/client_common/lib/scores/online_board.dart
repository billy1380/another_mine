import "package:another_mine_common/scores/online_config.dart";
import "package:another_mine_common/scores/score_category.dart";
import "package:willshex/willshex.dart" as ws;
import "package:willshex_embedding/willshex_embedding.dart";
import "package:willshex_online_player/willshex_online_player.dart";
import "package:willshex_scores/willshex_scores.dart" as scores;
import "package:willshex_space_cloud/data_type/session.dart";

/// A score as the online table lists it.
class OnlineScore {
  /// The score's id on the scores service; what its replay is found by.
  final int? id;
  final String name;
  final String? country;

  /// The country's flag, or null if there is none.
  final DialogImage? flag;

  /// The icon of the service the player is on.
  final DialogImage? service;

  /// The name of the service the player is on.
  final String? serviceName;
  final int seconds;
  final String board;
  final DateTime when;

  /// The recorded game, gzip then base64, or null if the score has none.
  final String? recording;

  const OnlineScore({
    this.id,
    required this.name,
    required this.country,
    required this.flag,
    required this.service,
    this.serviceName,
    required this.seconds,
    required this.board,
    required this.when,
    this.recording,
  });
}

/// The best scores kept online.
class OnlineBoard {
  final scores.CoreServiceClient _client;

  OnlineBoard({scores.CoreServiceClient? client})
    : _client = client ?? scores.CoreServiceClient();

  /// The best [count] scores of [category] from place [start], best first;
  /// empty for a category that is not kept online.
  Future<List<OnlineScore>> top(
    ScoreCategory category, {
    int count = 20,
    int start = 0,
  }) async {
    final int? id = OnlineConfig.categoryId(category);

    if (id == null) return const [];

    final scores.GetScoresResponse response = await _client.getScores(
      scores.GetScoresRequest(
        session: Session(accessCode: OnlineConfig.publisherKey),
        category: scores.Category(id: id),
        start: start,
        count: count,
        sortBy: scores.ScoreSortType.value,
        sortDirection: ws.SortDirectionType.ascending,
      ),
    );

    return [
      for (final scores.Score s in response.scores ?? <scores.Score>[])
        convert(s, board: category.label),
    ];
  }

  /// [s] as an online score; [board] is its board if it names none.
  static OnlineScore convert(scores.Score s, {String? board}) => OnlineScore(
    id: s.id,
    name: s.player?.name ?? "",
    service: s.player?.type == null ? null : serviceImage(s.player!.type!),
    serviceName: s.player?.type == null ? null : serviceName(s.player!.type!),
    flag: s.player?.country == null ? null : flagOf(s.player!.country!),
    country: s.player?.country == null ? null : countryName(s.player!.country!),
    seconds: s.value ?? 0,
    board: s.description ?? board ?? s.category?.name ?? "",
    when: s.when ?? DateTime.fromMillisecondsSinceEpoch(0),
    recording: s.additionalData,
  );

  /// The score with [id], or null if there is none.
  Future<OnlineScore?> find(int id) async {
    final scores.GetScoreResponse response = await _client.getScore(
      scores.GetScoreRequest(
        session: Session(accessCode: OnlineConfig.publisherKey),
        score: scores.Score(id: id),
      ),
    );

    final scores.Score? s = response.score;

    return s == null ? null : convert(s);
  }
}
