import "package:another_mine/pages/parts/app_drawer.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class ScoresPage extends StatefulWidget {
  static const String routePath = "/scores";
  static GoRouterWidgetBuilder builder =
      (context, state) => const ScoresPage._();

  const ScoresPage._();

  @override
  State<ScoresPage> createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
      ),
    );
  }
}
