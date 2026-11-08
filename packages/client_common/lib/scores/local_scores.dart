import "package:another_mine_common/scores/local_score.dart";
import "package:another_mine_common/scores/score_category.dart";
import "package:willshex_scores/willshex_scores.dart" as scores;
import "package:willshex_space_cloud/willshex_space_cloud.dart";
import "package:willshex_storage/storage.dart";

/// The high scores kept on this device, in a `willshex_storage` store.
///
/// They are the same `Score` entities that are later sent online (a category
/// by local id, a player, the board in the additional data), so a local score
/// can be submitted as it is.
///
/// [path] is where the store lives: a real folder on devices, a name in the
/// browser's file system on the web (`willshex_storage` uses `fs_shim`, which
/// picks the file system for the platform).
class LocalScores {
  final String path;

  /// How many scores each category keeps.
  final int retained;

  late final Storage _store = StorageProvider.provide(() => path);

  LocalScores(this.path, {this.retained = 20});

  /// The place [seconds] would take in [category] (1 is best), or null if it
  /// would not be among the best [retained]. A tie ranks below the score that
  /// got there first.
  Future<int?> rankOf(ScoreCategory category, int seconds) async {
    final List<scores.Score> existing = await _inCategory(category);
    final int rank =
        existing.where((s) => (s.value ?? 0) <= seconds).length + 1;

    return rank > retained ? null : rank;
  }

  /// Keeps [score] if it is among the best [retained] of its category and
  /// returns its place (1 is best), or returns null if it was not good enough.
  Future<int?> add(LocalScore score) async {
    final int? rank = await rankOf(score.category, score.seconds);

    if (rank == null) return null;

    final User player = await _player(score.name);

    await _store.save.entity(
      scores.Score(
        category: scores.Category(
          id: score.category.localId,
          name: score.category.label,
        ),
        player: player,
        device: Device(id: 1),
        value: score.seconds,
        description: score.board,
        when: score.when,
        attempt: 1,
        additionalData: score.toAdditionalData(),
      ),
    );

    await _trim(score.category);

    return rank;
  }

  /// The best scores of [category], best first.
  Future<List<LocalScore>> top(ScoreCategory category, {int? limit}) async {
    final List<scores.Score> best = _sorted(await _inCategory(category))
        .take(limit ?? retained)
        .toList();

    if (best.isEmpty) return const [];

    final Map<int, User> players = await _store.load.user.ids([
      for (final scores.Score s in best)
        if (s.player?.id != null) s.player!.id!,
    ]);

    return [
      for (final scores.Score s in best)
        _toLocalScore(s, category, players[s.player?.id]),
    ];
  }

  /// Forgets [score], which has to have come from the store (it needs an id).
  /// Does nothing for a score that has none.
  Future<void> remove(LocalScore score) async {
    final int? id = score.id;

    if (id != null) await _store.delete.entity(scores.Score(id: id));
  }

  /// Forgets every score of [category].
  Future<void> clearCategory(ScoreCategory category) async {
    final List<scores.Score> inCategory = await _inCategory(category);

    if (inCategory.isNotEmpty) await _store.delete.entities(inCategory);
  }

  /// Forgets every score.
  Future<void> clear() async {
    await _store.delete.all(scores.scoreStorageClass);
  }

  Future<List<scores.Score>> _inCategory(ScoreCategory category) => _store
      .load
      .score
      .filter("category=", scores.Category(id: category.localId))
      .list;

  List<scores.Score> _sorted(List<scores.Score> list) => list
    ..sort((a, b) {
      final int byValue = (a.value ?? 0).compareTo(b.value ?? 0);

      return byValue != 0
          ? byValue
          : (a.when ?? DateTime(0)).compareTo(b.when ?? DateTime(0));
    });

  Future<void> _trim(ScoreCategory category) async {
    final List<scores.Score> sorted = _sorted(await _inCategory(category));

    if (sorted.length > retained) {
      await _store.delete.entities(sorted.skip(retained));
    }
  }

  Future<User> _player(String name) async {
    final User? found = await _store.load.user.filter("name=", name).first;

    if (found != null) return found;

    final User created = User(name: name, type: UserTypeType.scores);
    created.id = await _store.save.entity(created);

    return created;
  }

  LocalScore _toLocalScore(
    scores.Score score,
    ScoreCategory category,
    User? player,
  ) {
    final Map<String, dynamic> data = LocalScore.parseAdditionalData(
      score.additionalData,
    );

    return LocalScore(
      id: score.id,
      name: player?.name ?? "",
      seconds: score.value ?? 0,
      category: category,
      width: data["width"] as int? ?? 0,
      height: data["height"] as int? ?? 0,
      mines: data["mines"] as int? ?? 0,
      solver: Solver.values.firstWhere(
        (s) => s.name == data["solver"],
        orElse: () => Solver.human,
      ),
      when: score.when ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
