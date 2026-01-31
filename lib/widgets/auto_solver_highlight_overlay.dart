import "package:another_mine/ai/interaction_type.dart";
import "package:another_mine/bloc/game/game_bloc.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class AutoSolverHighlightOverlay extends StatelessWidget {
  const AutoSolverHighlightOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GameBloc, GameState,
        (int?, InteractionType, int, int, Size)>(
      selector: (state) => (
        state.autoSolverLookingIndex,
        state.autoSolverLookingInteraction,
        state.difficulty.width,
        state.difficulty.height,
        state.gameSize
      ),
      builder: (context, data) {
        final (index, type, width, height, size) = data;

        if (index == null || width <= 0 || height <= 0) {
          return const SizedBox.shrink();
        }

        return IgnorePointer(
          child: CustomPaint(
            painter: _AutoSolverHighlightPainter(
              index: index,
              type: type,
              width: width,
              height: height,
              gameSize: size,
            ),
            size: size,
          ),
        );
      },
    );
  }
}

class _AutoSolverHighlightPainter extends CustomPainter {
  final int index;
  final InteractionType type;
  final int width;
  final int height;
  final Size gameSize;

  _AutoSolverHighlightPainter({
    required this.index,
    required this.type,
    required this.width,
    required this.height,
    required this.gameSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double tileWidth = gameSize.width / width;
    final double tileHeight = gameSize.height / height;

    final int row = index ~/ width;
    final int col = index % width;

    final Rect rect = Rect.fromLTWH(
      col * tileWidth,
      row * tileHeight,
      tileWidth,
      tileHeight,
    );

    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(8),
    );

    final Color color = switch (type) {
      InteractionType.probe => Colors.red,
      InteractionType.speculate => Colors.black,
      _ => Colors.transparent,
    };

    if (color == Colors.transparent) return;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_AutoSolverHighlightPainter oldDelegate) {
    return oldDelegate.index != index ||
        oldDelegate.type != type ||
        oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.gameSize != gameSize;
  }
}
