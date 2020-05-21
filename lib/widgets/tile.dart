import 'package:another_mine/model/game.dart';
import 'package:another_mine/model/tilemodel.dart';
import 'package:another_mine/model/tilestate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Tile extends StatefulWidget {
  final TileModel model;
  Tile(Key key, this.model) : super(key: key);

  @override
  _TileState createState() => _TileState(model);
}

class _TileState extends State<Tile> {
  final TileModel _model;

  _TileState(this._model);

  @override
  Widget build(BuildContext context) {
    String image = _image(_model.state);
    Game game = Provider.of<Game>(context, listen: false);

    return Container(
      child: GestureDetector(
        onSecondaryTapUp: (d) {
          if (!game.isFinished) {
            game.speculate(_model);
          }
        },
        child: FlatButton(
          padding: EdgeInsets.all(0),
          color: _model.state == TileState.NotPressed ? _model.colour : null,
          onPressed: () {
            if (!game.isFinished) {
              game.probe(_model);
            }
          },
          onLongPress: () {
            if (!game.isFinished) {
              game.speculate(_model);
            }
          },
          child: image == null ? null : Image.asset(image),
        ),
      ),
    );
  }

  String _image(TileState state) {
    String image;

    switch (state) {
      case TileState.DetenateBomb:
        image = "dead";
        break;
      case TileState.Eight:
        image = "eight";
        break;
      case TileState.Five:
        image = "five";
        break;
      case TileState.Four:
        image = "four";
        break;
      case TileState.One:
        image = "one";
        break;
      case TileState.PredictedBombCorrect:
        image = "found";
        break;
      case TileState.PredictedBombIncorrect:
        image = "not";
        break;
      case TileState.RevealedBomb:
        image = "hidden";
        break;
      case TileState.Seven:
        image = "seven";
        break;
      case TileState.Six:
        image = "six";
        break;
      case TileState.Three:
        image = "three";
        break;
      case TileState.Two:
        image = "two";
        break;
      case TileState.Unsure:
        image = "dunno";
        break;
      default:
        break;
    }

    return image == null ? null : "images/$image.png";
  }
}
