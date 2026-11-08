import "package:another_mine_common/scores/local_score.dart";
import "package:another_mine_common/scores/recording.dart";
import "package:willshex_embedding/willshex_embedding.dart";

/// A line of the scores table, from a local or an online score.
class ScoreRow {
  /// The score's id on the scores service; online scores only.
  final int? id;
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

  /// The recorded game, gzip then base64; online scores only, and only those
  /// that were sent with one.
  final String? recording;

  const ScoreRow({
    this.id,
    required this.name,
    required this.detail,
    this.country,
    this.flag,
    this.service,
    required this.seconds,
    required this.when,
    this.local,
    this.recording,
  });

  /// The recording to replay, or null if the score has none that can be.
  Recording? get replay => Recording.tryDecode(recording);
}
