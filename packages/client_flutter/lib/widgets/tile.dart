import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_common/model/tile_model.dart";
import "package:another_mine_common/model/tile_state_type.dart";
import "package:another_mine_common/presentation/presentation.dart";
import "package:another_mine_flutter/assets.dart";
import "package:another_mine_flutter/extensions/colour_ex.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:mine_images/mine_images.dart";

class Tile extends StatefulWidget {
  final TileModel model;
  final double? probability;
  final bool showProbability;

  const Tile(
    this.model, {
    super.key,
    this.probability,
    this.showProbability = false,
  });

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
    final MineImage? image = tileImage(widget.model.state);

    Widget content = image == null
        ? widget.model.state == TileStateType.revealedSafe
              ? const SizedBox()
              : Container(
                  decoration: BoxDecoration(
                    color: widget.model.colour.color,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                  ),
                )
        : Container(
            decoration: BoxDecoration(
              color: widget.model.state == TileStateType.detenateBomb
                  ? detonatedColour.color
                  : null,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: AnotherMineAssets.image(image),
          );

    // Overlay probability if enabled and appropriate: only for unrevealed or
    // flagged tiles, and not for very low probabilities.
    final double? prob = widget.probability;
    if (widget.showProbability &&
        prob != null &&
        showsProbability(widget.model.state, prob)) {
      content = Stack(
        alignment: Alignment.center,
        children: [
          content,
          Center(
            child: Text(
              "${(prob * 100).round()}",
              style: TextStyle(
                color: probabilityColour(prob, widget.model.colour).color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                shadows: [
                  Shadow(
                    blurRadius: 2.0,
                    color: probabilityShadow(widget.model.colour).color,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return content;
  }
}
