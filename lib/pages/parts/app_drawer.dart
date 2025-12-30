import 'package:another_mine/model/game_difficulty_type.dart';
import 'package:another_mine/pages/game_page.dart';
import 'package:another_mine/pages/scores_page.dart';
import 'package:another_mine/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:willshex/willshex.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text(
                "Difficulty",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _gameDifficultyTile(context, GameDifficultyType.beginner),
            _gameDifficultyTile(context, GameDifficultyType.intermediate),
            _gameDifficultyTile(context, GameDifficultyType.expert),
            const Divider(),
            ListTile(
              title: const Text("Scores"),
              onTap: () => GoRouter.of(context).go(ScoresPage.routePath),
            ),
            const Divider(),
            ListTile(
              title: const Text("Settings"),
              onTap: () => _showSettings(context),
            ),
            const Divider(),
            ListTile(
              title: const Text("About"),
              onTap: () => _showAbout(context),
            ),
          ],
        ),
      ),
    );
  }

  void _tap(BuildContext context, GameDifficultyType difficultyType) {
    Navigator.pop(context);

    GoRouter.of(context).go(GamePage.buildRoute(difficultyType));
  }

  void _showAbout(BuildContext context) {
    Navigator.pop(context);

    showAboutDialog(context: context);
  }

  void _showSettings(BuildContext context) {
    Navigator.pop(context);

    GoRouter.of(context).push(SettingsPage.routePath);
  }

  Widget _gameDifficultyTile(
      BuildContext context, GameDifficultyType difficulty) {
    return ListTile(
      title: Text(
          "${StringUtils.upperCaseFirstLetter(difficulty.name)} (${difficulty.description})"),
      onTap: () => _tap(context, difficulty),
    );
  }
}
