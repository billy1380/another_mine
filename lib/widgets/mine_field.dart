import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/widgets/focus_overlay.dart";
import "package:another_mine/widgets/tile.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class Minefield extends StatelessWidget {
  final ValueNotifier<int?>? focusIndexNotifier;
  final bool isFocusMode;
  final bool showProbabilities;

  const Minefield({
    super.key,
    this.focusIndexNotifier,
    this.isFocusMode = false,
    this.showProbabilities = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state.difficulty.width <= 0) return const SizedBox();

        return MouseRegion(
          onHover: focusIndexNotifier != null
              ? (event) => _onHover(event, state)
              : null,
          onExit: focusIndexNotifier != null
              ? (_) => focusIndexNotifier!.value = null
              : null,
          child: Stack(
            children: [
              _buildGrid(state),
              if (focusIndexNotifier != null) _buildFocusOverlay(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(GameState state) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.tiles.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: state.difficulty.width,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) => Tile(
        ValueKey(state.tiles[index].index),
        state.tiles[index],
        probability: state.start != null ? state.mineProbabilities[index] : null,
        showProbability: showProbabilities,
      ),
    );
  }

  Widget _buildFocusOverlay(GameState state) {
    return ValueListenableBuilder<int?>(
      valueListenable: focusIndexNotifier!,
      builder: (context, focusIndex, child) => RepaintBoundary(
        child: FocusOverlay(
          key: const ValueKey("focus_overlay"),
          enabled: isFocusMode,
          focusIndex: focusIndex,
          fieldWidth: state.difficulty.width,
          fieldHeight: state.difficulty.height,
          gameSize: state.gameSize,
        ),
      ),
    );
  }

  void _onHover(PointerHoverEvent event, GameState state) {
    final double tileWidth = state.gameSize.width / state.difficulty.width;
    final double tileHeight = state.gameSize.height / state.difficulty.height;

    final int col = (event.localPosition.dx / tileWidth)
        .floor()
        .clamp(0, state.difficulty.width - 1);
    final int row = (event.localPosition.dy / tileHeight)
        .floor()
        .clamp(0, state.difficulty.height - 1);
    final int index = row * state.difficulty.width + col;

    if (focusIndexNotifier!.value != index) {
      focusIndexNotifier!.value = index;
    }
  }
}
