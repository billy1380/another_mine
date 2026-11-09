import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_flutter/extensions/colour_ex.dart";
import "package:another_mine_flutter/widgets/auto_solver_highlight_overlay.dart";
import "package:another_mine_flutter/widgets/focus_overlay.dart";
import "package:another_mine_flutter/widgets/tile.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class Minefield extends StatefulWidget {
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
  State<Minefield> createState() => _MinefieldState();
}

class _MinefieldState extends State<Minefield> {
  Offset? _touchDown;
  bool _touchMoved = false;

  ValueNotifier<int?>? get focusIndexNotifier => widget.focusIndexNotifier;
  bool get isFocusMode => widget.isFocusMode;
  bool get showProbabilities => widget.showProbabilities;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state.difficulty.width <= 0) return const SizedBox();

        return MouseRegion(
          onHover: focusIndexNotifier != null
              ? (event) => _focusAt(event.localPosition, state)
              : null,
          onExit: focusIndexNotifier != null
              ? (_) => focusIndexNotifier!.value = null
              : null,
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: (e) => _onPointerUp(e, state),
            onPointerCancel: (_) => _touchDown = null,
            child: Stack(
              children: [
                _buildGrid(state),
                if (focusIndexNotifier != null) _buildFocusOverlay(state),
                const AutoSolverHighlightOverlay(),
              ],
            ),
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
      itemBuilder: (context, index) {
        final tileModel = state.tiles[index];
        return Tile(
          tileModel,
          key: ValueKey(tileModel.index),
          probability: state.start != null
              ? state.mineProbabilities[index]
              : null,
          showProbability: showProbabilities,
        );
      },
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
          gameSize: state.gameSize.size,
        ),
      ),
    );
  }

  // focus follows a press that stays put, so panning a big board leaves it be
  void _onPointerDown(PointerDownEvent e) {
    _touchDown = e.kind == PointerDeviceKind.touch ? e.localPosition : null;
    _touchMoved = false;
  }

  void _onPointerMove(PointerMoveEvent e) {
    final Offset? down = _touchDown;
    if (down != null && (e.localPosition - down).distance > kTouchSlop) {
      _touchMoved = true;
    }
  }

  void _onPointerUp(PointerUpEvent e, GameState state) {
    if (_touchDown != null && !_touchMoved && focusIndexNotifier != null) {
      _focusAt(e.localPosition, state);
    }
    _touchDown = null;
  }

  void _focusAt(Offset position, GameState state) {
    final double tileWidth = state.gameSize.width / state.difficulty.width;
    final double tileHeight = state.gameSize.height / state.difficulty.height;

    final int col = (position.dx / tileWidth).floor().clamp(
      0,
      state.difficulty.width - 1,
    );
    final int row = (position.dy / tileHeight).floor().clamp(
      0,
      state.difficulty.height - 1,
    );
    final int index = row * state.difficulty.width + col;

    if (focusIndexNotifier!.value != index) {
      focusIndexNotifier!.value = index;
    }
  }
}
