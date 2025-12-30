import "package:another_mine/pages/game_page.dart";
import "package:another_mine/pages/scores_page.dart";
import "package:another_mine/pages/settings_page.dart";
import "package:another_mine/pages/startup_page.dart";
import "package:another_mine/services/pref.dart";
import "package:go_router/go_router.dart";

final GoRouter router = GoRouter(
  initialLocation: StartupPage.routerPath,
  routes: [
    GoRoute(
      name: "StartupPage",
      path: StartupPage.routerPath,
      builder: StartupPage.builder,
    ),
    GoRoute(
      name: "GamePage",
      path: GamePage.routePath,
      builder: GamePage.builder,
    ),
    GoRoute(
      name: "SettingsPage",
      path: SettingsPage.routePath,
      builder: SettingsPage.builder,
    ),
    GoRoute(
      name: "ScoresPage",
      path: ScoresPage.routePath,
      builder: ScoresPage.builder,
    ),
  ],
  debugLogDiagnostics: true,
  redirect: (context, state) {
    if (!Pref.service.isInitialized &&
        state.matchedLocation != StartupPage.routerPath) {
      return Uri(
        path: StartupPage.routerPath,
        queryParameters: {
          if (state.uri.toString() != "/") "from": state.uri.toString(),
        },
      ).toString();
    }

    return null;
  },
);
