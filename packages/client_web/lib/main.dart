import "package:another_mine_web/app.dart";
import "package:jaspr/jaspr.dart";
import "package:logging/logging.dart";

void main() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print("[${record.level.name}] ${record.loggerName}: ${record.message}");
  });

  runApp(const App());
}
