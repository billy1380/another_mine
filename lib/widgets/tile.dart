import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/tile_model.dart";
import "package:another_mine/model/tile_state_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class Tile extends StatefulWidget {
  final TileModel model;
  const Tile(Key key, this.model) : super(key: key);

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> {
  @override
  Widget build(BuildContext context) {
    final GameBloc bloc = BlocProvider.of<GameBloc>(context);

    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return state.autoSolverEnabled
            ? _tile()
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onSecondaryTap: () {
                  if (state.isNotFinished) {
                    bloc.add(Speculate(model: widget.model));
                  }
                },
                onTapDown: (d) {
                  if (state.isNotFinished) {
                    bloc.add(MightPlay(model: widget.model));
                  }
                },
                onTapCancel: () {
                  if (state.isNotFinished) {
                    bloc.add(const DonePlaying());
                  }
                },
                onTap: () {
                  if (state.isNotFinished) {
                    bloc
                      ..add(Probe(model: widget.model))
                      ..add(const DonePlaying());
                  }
                },
                onLongPress: () {
                  if (state.isNotFinished) {
                    bloc.add(Speculate(model: widget.model));
                  }
                },
                child: _tile(),
              );
      },
    );
  }

  Widget _tile() {
    String? image = _image(widget.model.state);

    return image == null
        ? widget.model.state == TileStateType.revealedSafe
            ? Container()
            : Container(
                decoration: BoxDecoration(
                    color: widget.model.colour,
                    borderRadius: const BorderRadius.all(Radius.circular(5))),
              )
        : Container(
            decoration: BoxDecoration(
                color: widget.model.state == TileStateType.detenateBomb
                    ? const Color.fromARGB(0xFF, 0xE2, 0x41, 0x00)
                    : null,
                borderRadius: const BorderRadius.all(Radius.circular(5))),
            child: Image.asset(image),
          );
  }

  String? _image(TileStateType state) {
    String? image;

    switch (state) {
      case TileStateType.detenateBomb:
        image = "dead";
        break;
      case TileStateType.eight:
        image = "eight";
        break;
      case TileStateType.five:
        image = "five";
        break;
      case TileStateType.four:
        image = "four";
        break;
      case TileStateType.one:
        image = "one";
        break;
      case TileStateType.predictedBombCorrect:
        image = "found";
        break;
      case TileStateType.predictedBombIncorrect:
        image = "not";
        break;
      case TileStateType.revealedBomb:
        image = "hidden";
        break;
      case TileStateType.seven:
        image = "seven";
        break;
      case TileStateType.six:
        image = "six";
        break;
      case TileStateType.three:
        image = "three";
        break;
      case TileStateType.two:
        image = "two";
        break;
      case TileStateType.unsure:
        image = "dunno";
        break;
      default:
        break;
    }

    return image == null ? null : "images/$image.png";
  }
}
