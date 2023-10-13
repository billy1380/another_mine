import 'package:another_mine/model/game.dart';
import 'package:another_mine/model/gamedifficulty.dart';
import 'package:another_mine/model/gamestate.dart';
import 'package:another_mine/services/pref.dart';
import 'package:another_mine/widgets/digits.dart';
import 'package:another_mine/widgets/gametimer.dart';
import 'package:another_mine/widgets/minefield.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const String difficultySettingName = "difficulty";

class AnotherMineGamePage extends StatefulWidget {
  const AnotherMineGamePage({super.key});

  @override
  State<AnotherMineGamePage> createState() => _AnotherMineGamePageState();
}

class _AnotherMineGamePageState extends State<AnotherMineGamePage> {
  Game? _game;

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
                child: const ListTile(
                  title: Text("Difficulty"),
                )),
            ListTile(
                title: Text("Beginner (${GameDifficulty.beginner.describe()})"),
                onTap: () => _tap(context, beginnerName)),
            ListTile(
                title: Text(
                    "Intermediate (${GameDifficulty.intermediate.describe()})"),
                onTap: () => _tap(context, intermediateName)),
            ListTile(
                title: Text("Expert (${GameDifficulty.expert.describe()})"),
                onTap: () => _tap(context, expertName))
          ],
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        title: ChangeNotifierProvider.value(
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
                const GameTimer(),
              ],
            );
          }),
        ),
      ),
      body: ChangeNotifierProvider.value(
        value: _game,
        child: Consumer<Game>(builder: (context, game, _) {
          return const Minefield();
        }),
      ),
    );
  }

  String _image(GameState state) {
    String image = "well";
    switch (state) {
      case GameState.lost:
        image = "restin";
        break;
      case GameState.won:
        image = "cool";
        break;
      case GameState.thinking:
        image = "thinking";
        break;
      default:
        break;
    }

    return "images/$image.png";
  }

  void _tap(BuildContext context, String difficultyName) {
    final String? name = Pref.service.getString(difficultySettingName);
    if (name != difficultyName) {
      Pref.service.setString(difficultySettingName, difficultyName);
      _newGame();
    }

    Navigator.pop(context);
  }

  void _newGame() {
    final String name =
        Pref.service.getString(difficultySettingName) ?? "beginner";
    GameDifficulty difficulty = GameDifficulty.fromString(name);

    setState(() {
      _game = Game()
        ..difficulty = difficulty
        ..colour = Theme.of(context).primaryColor
        ..start();
    });

    // TODO: resize the window
    // if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    //   getWindowInfo().then((value) {
    //     setWindowTitle(StringUtils.upperCaseFirstLetter(name));
    //     setWindowFrame(Rect.fromLTRB(
    //         value.frame.left,
    //         value.frame.top,
    //         value.frame.left + _game!.difficulty.width * 40,
    //         value.frame.top + _game!.difficulty.height * 40 + 78));
    //   });
    // }
  }
}
