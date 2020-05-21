import 'dart:io';
import 'dart:ui';

import 'package:another_mine/model/game.dart';
import 'package:another_mine/model/gamedifficulty.dart';
import 'package:another_mine/model/gamestate.dart';
import 'package:another_mine/widgets/digits.dart';
import 'package:another_mine/widgets/gametimer.dart';
import 'package:another_mine/widgets/minefield.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';
import 'package:provider/provider.dart';
import 'package:willshex/willshex.dart';
import 'package:window_size/window_size.dart';

const String DIFFICULTY_SETTING = "difficulty";

class AnotherMineGamePage extends StatefulWidget {
  @override
  _AnotherMineGamePageState createState() => _AnotherMineGamePageState();
}

class _AnotherMineGamePageState extends State<AnotherMineGamePage> {
  Game _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _newGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            Container(
                color: Theme.of(context).secondaryHeaderColor,
                child: ListTile(
                  title: Text("Difficulty"),
                )),
            ListTile(
                title: Text("Beginner (${GameDifficulty.BEGINNER.describe()})"),
                onTap: () => _tap(context, BEGINNER_NAME)),
            ListTile(
                title: Text(
                    "Intermediate (${GameDifficulty.INTERMEDIATE.describe()})"),
                onTap: () => _tap(context, INTERMEDIATE_NAME)),
            ListTile(
                title: Text("Expert (${GameDifficulty.EXPERT.describe()})"),
                onTap: () => _tap(context, EXPERT_NAME))
          ],
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        title: Container(
          child: ChangeNotifierProvider.value(
            value: _game,
            child: Consumer<Game>(builder: (context, game, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Digits(name: "Mines", value: game.minesMarked),
                  Tooltip(
                    message: "Start new game",
                    child: MaterialButton(
                      onPressed: _newGame,
                      child: Image.asset(
                        _image(game.state),
                        height: 45,
                      ),
                    ),
                  ),
                  GameTimer(),
                ],
              );
            }),
          ),
        ),
      ),
      body: ChangeNotifierProvider.value(
        value: _game,
        child: Consumer<Game>(builder: (context, game, _) {
          return Minefield();
        }),
      ),
    );
  }

  String _image(GameState state) {
    String image = "well";
    switch (state) {
      case GameState.Lost:
        image = "restin";
        break;
      case GameState.Won:
        image = "cool";
        break;
      case GameState.Thinking:
        image = "thinking";
        break;
      default:
        break;
    }

    return "images/$image.png";
  }

  void _tap(BuildContext context, String difficultyName) {
    final String name = PrefService.getString(DIFFICULTY_SETTING);
    if (name != difficultyName) {
      PrefService.setString(DIFFICULTY_SETTING, difficultyName);
      _newGame();
    }

    Navigator.pop(context);
  }

  void _newGame() {
    final String name = PrefService.getString(DIFFICULTY_SETTING);
    GameDifficulty difficulty = GameDifficulty.fromString(name);

    setState(() {
      _game = Game()
        ..difficulty = difficulty
        ..colour = Theme.of(context).primaryColor
        ..start();
    });

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      getWindowInfo().then((value) {
        setWindowTitle(
            StringUtils.upperCaseFirstLetter(name == null ? "beginner" : name));
        setWindowFrame(Rect.fromLTRB(
            value.frame.left,
            value.frame.top,
            value.frame.left + _game.difficulty.width * 40,
            value.frame.top + _game.difficulty.height * 40 + 78));
      });
    }
  }
}
