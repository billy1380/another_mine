import 'package:another_mine/model/game.dart';
import 'package:another_mine/model/tilemodel.dart';
import 'package:another_mine/model/tilestate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Tile extends StatefulWidget {
  final TileModel model;
  const Tile(Key key, this.model) : super(key: key);

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> {
  @override
  Widget build(BuildContext context) {
    String? image = _image(widget.model.state);
    Game game = Provider.of<Game>(context, listen: false);

    return GestureDetector(
      onSecondaryTapUp: (d) {
        if (!game.isFinished) {
          game.speculate(widget.model);
        }
      },
      child: TextButton(
        // TODO: color: _model.state == TileState.NotPressed ? _model.colour : null,
        onPressed: () {
          if (!game.isFinished) {
            game.probe(widget.model);
          }
        },
        onLongPress: () {
          if (!game.isFinished) {
            game.speculate(widget.model);
          }
        },
        child: image == null ? Container() : Image.asset(image),
      ),
    );
  }

  String? _image(TileState state) {
    String? image;

    switch (state) {
      case TileState.detenateBomb:
        image = "dead";
        break;
      case TileState.eight:
        image = "eight";
        break;
      case TileState.five:
        image = "five";
        break;
      case TileState.four:
        image = "four";
        break;
      case TileState.one:
        image = "one";
        break;
      case TileState.predictedBombCorrect:
        image = "found";
        break;
      case TileState.predictedBombIncorrect:
        image = "not";
        break;
      case TileState.revealedBomb:
        image = "hidden";
        break;
      case TileState.seven:
        image = "seven";
        break;
      case TileState.six:
        image = "six";
        break;
      case TileState.three:
        image = "three";
        break;
      case TileState.two:
        image = "two";
        break;
      case TileState.unsure:
        image = "dunno";
        break;
      default:
        break;
    }

    return image == null ? null : "images/$image.png";
  }
}
