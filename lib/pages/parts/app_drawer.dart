import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/pages/game_page.dart";
import "package:another_mine/pages/scores_page.dart";
import "package:another_mine/pages/settings_page.dart";
import "package:another_mine/services/pref.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:willshex/willshex.dart";

const int minWidth = 5;
const int maxWidth = 50;
const int minHeight = 5;
const int maxHeight = 50;

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
            _gameDifficultyTile(context, GameDifficulty.beginner),
            _gameDifficultyTile(context, GameDifficulty.intermediate),
            _gameDifficultyTile(context, GameDifficulty.expert),
            _gameDifficultyTile(context),
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

  void _tap(BuildContext context, GameDifficulty? difficultyType) {
    if (difficultyType == null) {
      Navigator.pop(context);
      _showCustomDifficultyDialog(context);
    } else {
      Navigator.pop(context);

      GoRouter.of(context).go(GamePage.buildRoute(difficultyType));
    }
  }

  Future<void> _showCustomDifficultyDialog(BuildContext context) async {
    int width = Pref.service.getInt("width") ?? GameDifficulty.beginner.width;
    int height =
        Pref.service.getInt("height") ?? GameDifficulty.beginner.height;
    int mines = Pref.service.getInt("mines") ?? GameDifficulty.beginner.mines;
    int maxMines = (width * height) - 9;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updateMaxMines() {
              int newMax = (width * height) - 9;
              if (newMax < 0) newMax = 0;
              if (mines > newMax) {
                mines = newMax;
              }
              maxMines = newMax;
              if (mines < 1) mines = 1;
              if (maxMines < 1) maxMines = 1;
            }

            return AlertDialog(
              title: const Text("Custom Game"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Width"),
                    Row(
                      children: [
                        Text("$minWidth"),
                        Expanded(
                          child: Slider(
                            value: width.toDouble(),
                            min: minWidth.toDouble(),
                            max: maxWidth.toDouble(),
                            divisions: maxWidth - minWidth,
                            label: width.toString(),
                            onChanged: (value) {
                              setState(() {
                                width = value.toInt();
                                updateMaxMines();
                              });
                            },
                          ),
                        ),
                        Text("$maxWidth"),
                      ],
                    ),
                    Text("Current Width: $width"),
                    const SizedBox(height: 16),
                    const Text("Height"),
                    Row(
                      children: [
                        Text("$minHeight"),
                        Expanded(
                          child: Slider(
                            value: height.toDouble(),
                            min: minHeight.toDouble(),
                            max: maxHeight.toDouble(),
                            divisions: maxHeight - minHeight,
                            label: height.toString(),
                            onChanged: (value) {
                              setState(() {
                                height = value.toInt();
                                updateMaxMines();
                              });
                            },
                          ),
                        ),
                        Text("$maxHeight"),
                      ],
                    ),
                    Text("Current Height: $height"),
                    const SizedBox(height: 16),
                    const Text("Mines"),
                    Row(
                      children: [
                        const Text("1"),
                        Expanded(
                          child: Slider(
                            value: mines.toDouble(),
                            min: 1,
                            max: maxMines.toDouble(),
                            divisions: maxMines > 1 ? maxMines - 1 : 1,
                            label: mines.toString(),
                            onChanged: (value) {
                              setState(() {
                                mines = value.toInt();
                              });
                            },
                          ),
                        ),
                        Text("$maxMines"),
                      ],
                    ),
                    Text("Current Mines: $mines"),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Pref.service.setInt("width", width);
                    Pref.service.setInt("height", height);
                    Pref.service.setInt("mines", mines);

                    if (context.mounted) {
                      Navigator.pop(context);

                      GoRouter.of(context)
                          .go(GamePage.buildRoute(GameDifficulty.custom(
                        width: width,
                        height: height,
                        mines: mines,
                      )));
                    }
                  },
                  child: const Text("Start"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAbout(BuildContext context) {
    Navigator.pop(context);

    showAboutDialog(context: context);
  }

  void _showSettings(BuildContext context) {
    Navigator.pop(context);

    GoRouter.of(context).push(SettingsPage.routePath);
  }

  Widget _gameDifficultyTile(BuildContext context,
      [GameDifficulty? difficulty]) {
    return ListTile(
      title: Text(
          "${StringUtils.upperCaseFirstLetter(difficulty?.name ?? customName)}${difficulty == null ? "" : " (${difficulty.description})"}"),
      onTap: () => _tap(context, difficulty),
    );
  }
}
