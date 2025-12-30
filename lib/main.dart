import "package:another_mine/app.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:willshex/willshex.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BrowserContextMenu.disableContextMenu();

  setupLogging();

  runApp(const App());
}
