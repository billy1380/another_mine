import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/pages/game_page.dart";
import "package:another_mine/services/pref.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:willshex/willshex.dart";

class StartupPage extends StatelessWidget {
  static const String routerPath = "/startup";

  static GoRouterWidgetBuilder builder = (context, state) => StartupPage._(
        from: state.uri.queryParameters["from"],
      );

  final String? from;

  const StartupPage._({
    this.from,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _init(),
        initialData: null,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            SchedulerBinding.instance.addPostFrameCallback((timeStamp) =>
                GoRouter.of(context)
                    .go(from ?? GamePage.buildRoute(GameDifficulty.beginner)));
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Future<bool> _init() async {
    setupLogging();

    if (kIsWeb) {
      await BrowserContextMenu.disableContextMenu();
    }

    return await Pref.service.init("another_mine_");
  }
}
