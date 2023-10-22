import 'package:another_mine/app.dart';
import 'package:flutter/material.dart';
import 'package:willshex/willshex.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  setupLogging();

  runApp(const App());
}
