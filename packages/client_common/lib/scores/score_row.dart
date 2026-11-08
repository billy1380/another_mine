import "package:another_mine_common/scores/local_score.dart";
import "package:willshex_embedding/willshex_embedding.dart";

/// A line of the scores table, from a local or an online score.
class ScoreRow {
  final String name;
  final String detail;

  /// The player's country, and its flag if it has one; online scores only.
  final String? country;
  final DialogImage? flag;

  /// The icon of the player's service; online scores only.
  final DialogImage? service;
  final int seconds;
  final DateTime when;

  /// The local score this is, which is what gets deleted; null for an online one.
  final LocalScore? local;

  const ScoreRow({
    required this.name,
    required this.detail,
    this.country,
    this.flag,
    this.service,
    required this.seconds,
    required this.when,
    this.local,
  });
}
