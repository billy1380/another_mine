import "package:flutter/foundation.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

/// Where this device keeps its scores, or null on the web, where the game uses
/// a name in the browser's file system.
Future<String?> scoresStorePath() async {
  if (kIsWeb) return null;

  final dir = await getApplicationSupportDirectory();

  return p.join(dir.path, "AnotherMine", "scores");
}
