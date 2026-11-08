import "package:another_mine_common/scores/online_config.dart";
import "package:another_mine_common/scores/score_category.dart";
import "package:willshex/willshex.dart" as ws;
import "package:willshex_embedding/willshex_embedding.dart";
import "package:willshex_online_player/willshex_online_player.dart";
import "package:willshex_scores/willshex_scores.dart" as scores;
import "package:willshex_space_cloud/data_type/session.dart";

/// A score as the online table lists it.
class OnlineScore {
  final String name;
  final String? country;

  /// The country's flag, or null if there is none.
  final DialogImage? flag;
  final int seconds;
  final String board;
  final DateTime when;

  const OnlineScore({
    required this.name,
    required this.country,
    required this.flag,
    required this.seconds,
    required this.board,
    required this.when,
  });
}

/// The best scores kept online.
class OnlineBoard {
  final scores.CoreServiceClient _client;

  OnlineBoard({scores.CoreServiceClient? client})
    : _client = client ?? scores.CoreServiceClient();

  /// The best [count] scores of [category], best first; empty for a category
  /// that is not kept online.
  Future<List<OnlineScore>> top(
    ScoreCategory category, {
    int count = 20,
  }) async {
    final int? id = OnlineConfig.categoryId(category);

    if (id == null) return const [];

    final scores.GetScoresResponse response = await _client.getScores(
      scores.GetScoresRequest(
        session: Session(accessCode: OnlineConfig.publisherKey),
        category: scores.Category(id: id),
        start: 0,
        count: count,
        sortBy: scores.ScoreSortType.value,
        sortDirection: ws.SortDirectionType.ascending,
      ),
    );

    return [
      for (final scores.Score s in response.scores ?? <scores.Score>[])
        OnlineScore(
          name: s.player?.name ?? "",
          flag: s.player?.country == null ? null : flagOf(s.player!.country!),
          country: s.player?.country == null
              ? null
              : countryName(s.player!.country!),
          seconds: s.value ?? 0,
          board: s.description ?? category.label,
          when: s.when ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
    ];
  }
}
