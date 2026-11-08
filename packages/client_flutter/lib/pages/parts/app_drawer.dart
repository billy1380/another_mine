import "package:another_mine_common/dialogs/custom_game_form.dart";
import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/strings.dart";
import "package:another_mine_flutter/pages/game_page.dart";
import "package:another_mine_flutter/pages/scores_page.dart";
import "package:another_mine_flutter/pages/settings_page.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:willshex/willshex.dart";

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentLocation = GoRouterState.of(context).uri.path;

    return Drawer(
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text(
                Strings.difficulty,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _gameDifficultyTile(
              context,
              currentLocation,
              GameDifficulty.beginner,
            ),
            _gameDifficultyTile(
              context,
              currentLocation,
              GameDifficulty.intermediate,
            ),
            _gameDifficultyTile(
              context,
              currentLocation,
              GameDifficulty.expert,
            ),
            _gameDifficultyTile(context, currentLocation),
            const Divider(),
            ListTile(
              title: const Text(Strings.scores),
              selected: currentLocation == ScoresPage.routePath,
              onTap: () => GoRouter.of(context).go(ScoresPage.routePath),
            ),
            const Divider(),
            ListTile(
              title: const Text(Strings.settingsTitle),
              selected: currentLocation.startsWith(SettingsPage.routePath),
              onTap: () => _showSettings(context),
            ),
          ],
        ),
      ),
    );
  }

  void _tap(BuildContext context, GameDifficulty? difficultyType) {
    if (difficultyType == null) {
      _showCustomDifficultyDialog(context);
    } else {
      Navigator.pop(context);

      GoRouter.of(context).go(GamePage.buildRoute(difficultyType));
    }
  }

  Future<void> _showCustomDifficultyDialog(BuildContext context) async {
    final GameDifficulty? difficulty = await CustomGameForm.ask();

    if (!context.mounted) return;

    // the drawer closes whether or not a board was chosen
    Navigator.pop(context);

    if (difficulty != null) {
      GoRouter.of(context).go(GamePage.buildRoute(difficulty));
    }
  }

  void _showSettings(BuildContext context) {
    Navigator.pop(context);

    GoRouter.of(context).push(SettingsPage.routePath);
  }

  Widget _gameDifficultyTile(
    BuildContext context,
    String currentLocation, [
    GameDifficulty? difficulty,
  ]) {
    final bool isSelected = _isGamePageWithDifficulty(
      currentLocation,
      difficulty,
    );

    return ListTile(
      title: Text(
        "${StringUtils.upperCaseFirstLetter(difficulty?.name ?? customName)}${difficulty == null ? "" : " (${difficulty.description})"}",
      ),
      selected: isSelected,
      onTap: () => _tap(context, difficulty),
    );
  }

  bool _isGamePageWithDifficulty(
    String currentLocation,
    GameDifficulty? difficulty,
  ) {
    if (!currentLocation.startsWith("/game")) return false;

    if (difficulty == null) {
      return currentLocation.contains("/custom");
    }

    return currentLocation.contains("/${difficulty.name}");
  }
}
