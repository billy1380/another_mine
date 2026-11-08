import "dart:convert";
import "dart:typed_data";

import "package:another_mine_common/model/game_difficulty.dart";
import "package:archive/archive.dart";

/// One thing the player did: `p` reveal and `f` flag a [tile], `pause` and
/// `resume`, and `prob` and `focus` turned on or off ([on]).
class ReplayEvent {
  final int ms;
  final String code;
  final int? argument;

  const ReplayEvent(this.ms, this.code, [this.argument]);

  bool get isMove => code == "p" || code == "f";
  bool get on => argument == 1;
}

/// A recorded game, decoded from a score's additional data (gzip, then base64
/// JSON, as `ScoreSubmitter.encode` writes it).
class Recording {
  static const int version = 2;

  final String difficulty;
  final int width;
  final int height;
  final int mines;
  final String solver;
  final Uint8List layout;
  final List<ReplayEvent> events;

  const Recording({
    required this.difficulty,
    required this.width,
    required this.height,
    required this.mines,
    required this.solver,
    required this.layout,
    required this.events,
  });

  /// The recording in [data]; throws a [FormatException] if it is not one this
  /// version can replay.
  factory Recording.decode(String data) {
    try {
      final Map<String, dynamic> json = jsonDecode(
        utf8.decode(GZipDecoder().decodeBytes(base64.decode(data))),
      ) as Map<String, dynamic>;

      if (json["game"] != "anothermine" || json["version"] != version) {
        throw const FormatException("Not a recording of this game");
      }

      final Recording recording = Recording(
        difficulty: json["difficulty"] as String,
        width: json["width"] as int,
        height: json["height"] as int,
        mines: json["mines"] as int,
        solver: json["solver"] as String,
        layout: base64.decode(json["layout"] as String),
        events: [
          for (final dynamic e in json["events"] as List)
            ReplayEvent(
              (e as List)[0] as int,
              e[1] as String,
              e.length > 2 ? e[2] as int : null,
            ),
        ],
      );

      if (recording.layout.length * 8 < recording.width * recording.height) {
        throw const FormatException("The layout is too short for the board");
      }

      return recording;
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException("Not a recording: $e");
    }
  }

  /// The recording in [data], or null if there is none to replay.
  static Recording? tryDecode(String? data) {
    if (data == null || data.isEmpty) return null;

    try {
      return Recording.decode(data);
    } on FormatException {
      return null;
    }
  }

  GameDifficulty get gameDifficulty =>
      GameDifficulty.custom(width: width, height: height, mines: mines);

  bool hasMine(int index) => layout[index >> 3] & (1 << (index & 7)) != 0;
}
