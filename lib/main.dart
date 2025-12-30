import "package:another_mine/app.dart";
import "package:flutter/material.dart";
import "package:willshex/willshex.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupLogging();

  runApp(const App());
}
