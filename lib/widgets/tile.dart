import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/tile_model.dart";
import "package:another_mine/model/tile_state_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class Tile extends StatefulWidget {
  final TileModel model;
  final double? probability;
  final bool showProbability;

  const Tile(
    Key key,
    this.model, {
    this.probability,
    this.showProbability = false,
  }) : super(key: key);

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> {
  bool _isValidTap = false;

  @override
  Widget build(BuildContext context) {
    final GameBloc bloc = BlocProvider.of<GameBloc>(context);

    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return state.autoSolverEnabled
            ? _tile()
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onSecondaryTapDown: (d) {
                  _isValidTap = true;
                },
                onSecondaryTapUp: (d) {
                  if (_isValidTap && state.isNotFinished) {
                    bloc.add(Speculate(model: widget.model));
                  }
                  _isValidTap = false;
                },
                onSecondaryTapCancel: () {
                  _isValidTap = false;
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

    Widget content = image == null
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

    // Overlay probability if enabled and appropriate
    if (widget.showProbability && widget.probability != null) {
      // Only show for unrevealed/flagged tiles
      if (widget.model.state == TileStateType.notPressed ||
          widget.model.state == TileStateType.unsure) {
        final prob = widget.probability!;

        // Hide very low probabilities, but show 0% (if < 0.01 but not 0.0, hide)
        // If prob is 0.0, show "0%". If > 0.01, show %.
        // Condition: Hide if (prob > 0.0 && prob < 0.01)

        bool shouldShow = !(prob < 0.01);

        if (shouldShow) {
          return Stack(
            alignment: Alignment.center,
            children: [
              content,
              Center(
                child: Text(
                  "${(prob * 100).round()}",
                  style: TextStyle(
                    color: _getColorForProbability(prob),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: widget.model.colour.computeLuminance() > 0.5
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.8),
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      }
    }

    return content;
  }

  Color _getColorForProbability(double prob) {
    Color baseColor;
    if (prob <= 0.5) {
      baseColor = Color.lerp(Colors.green, Colors.orange, prob * 2)!;
    } else {
      baseColor = Color.lerp(Colors.orange, Colors.red, (prob - 0.5) * 2)!;
    }

    // Check tile background luminance
    // If tile is dark, use lighter/brighter probability colors
    // If tile is light, use darker probability colors
    bool isDarkBackground = widget.model.colour.computeLuminance() < 0.5;

    if (isDarkBackground) {
      // Brighten the color for dark backgrounds
      return HSLColor.fromColor(baseColor).withLightness(0.65).toColor();
    } else {
      // Darken the color for light backgrounds
      return HSLColor.fromColor(baseColor).withLightness(0.35).toColor();
    }
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
