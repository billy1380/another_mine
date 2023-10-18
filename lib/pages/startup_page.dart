import 'package:another_mine/pages/game_page.dart';
import 'package:another_mine/services/pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

class StartupPage extends StatelessWidget {
  static const String routerPath = "/startup";

  static GoRouterWidgetBuilder builder =
      (context, state) => const StartupPage._();

  const StartupPage._();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: Pref.service.init("another_mine_"),
        initialData: null,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            SchedulerBinding.instance.addPostFrameCallback(
                (timeStamp) => GoRouter.of(context).go(GamePage.buildRoute()));
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
