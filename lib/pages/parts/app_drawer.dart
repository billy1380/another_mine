import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/pages/game_page.dart";
import "package:another_mine/pages/parts/custom_game_body.dart";
import "package:another_mine/pages/parts/custom_game_title.dart";
import "package:another_mine/pages/scores_page.dart";
import "package:another_mine/pages/settings_page.dart";
import "package:another_mine/services/provider.dart";
import "package:another_mine/strings.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:willshex/willshex.dart";

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentLocation = GoRouterState.of(context).uri.path;

    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
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
                  state,
                  GameDifficulty.beginner,
                ),
                _gameDifficultyTile(
                  context,
                  currentLocation,
                  state,
                  GameDifficulty.intermediate,
                ),
                _gameDifficultyTile(
                  context,
                  currentLocation,
                  state,
                  GameDifficulty.expert,
                ),
                _gameDifficultyTile(context, currentLocation, state),
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
      },
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
    final difficulty = Provider.pref.difficulty;
    int width = difficulty.width;
    int height = difficulty.height;
    int mines = difficulty.mines;
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
              title: CustomGameTitle(
                width: width,
                height: height,
                mines: mines,
                onDifficultySelected: (value) {
                  setState(() {
                    width = value.width;
                    height = value.height;
                    mines = value.mines;
                    updateMaxMines();
                  });
                },
              ),
              content: CustomGameBody(
                width: width,
                height: height,
                mines: mines,
                maxMines: maxMines,
                onWidthChanged: (value) {
                  setState(() {
                    width = value;
                    updateMaxMines();
                  });
                },
                onHeightChanged: (value) {
                  setState(() {
                    height = value;
                    updateMaxMines();
                  });
                },
                onMinesChanged: (value) {
                  setState(() {
                    mines = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(Strings.cancel),
                ),
                TextButton(
                  onPressed: () {
                    Provider.pref.setInt("width", width);
                    Provider.pref.setInt("height", height);
                    Provider.pref.setInt("mines", mines);

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
                  child: const Text(Strings.start),
                ),
              ],
            );
          },
        );
      },
    );

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void _showSettings(BuildContext context) {
    Navigator.pop(context);

    GoRouter.of(context).push(SettingsPage.routePath);
  }

  Widget _gameDifficultyTile(
    BuildContext context,
    String currentLocation,
    GameState state, [
    GameDifficulty? difficulty,
  ]) {
    final bool isSelected =
        _isGamePageWithDifficulty(currentLocation, difficulty);

    Widget? badge;

    final bool isCurrentGameDifficulty = difficulty == null
        ? state.difficulty.name == customName
        : state.difficulty == difficulty;

    if (isCurrentGameDifficulty && state.isNotFinished) {
      final Color bgColor = Provider.pref.effectiveCustomBgColor;
      final Color textColor =
          bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

      String text;
      if (difficulty == null) {
        text = "${state.minesMarked}/${state.difficulty.mines}";
      } else {
        text = "${state.difficulty.mines - state.minesMarked}";
      }

      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return ListTile(
      title: Text(
          "${StringUtils.upperCaseFirstLetter(difficulty?.name ?? customName)}${difficulty == null ? "" : " (${difficulty.description})"}"),
      selected: isSelected,
      trailing: badge,
      onTap: () => _tap(context, difficulty),
    );
  }

  bool _isGamePageWithDifficulty(
      String currentLocation, GameDifficulty? difficulty) {
    if (!currentLocation.startsWith("/game")) return false;

    if (difficulty == null) {
      return currentLocation.contains("/custom");
    }

    return currentLocation.contains("/${difficulty.name}");
  }
}
