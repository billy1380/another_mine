import "package:flutter/material.dart";

class FocusOverlay extends StatelessWidget {
  final bool enabled;
  final int? focusIndex;
  final int fieldWidth;
  final int fieldHeight;
  final Size gameSize;

  const FocusOverlay({
    super.key,
    required this.enabled,
    required this.focusIndex,
    required this.fieldWidth,
    required this.fieldHeight,
    required this.gameSize,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || focusIndex == null) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        painter: FocusOverlayPainter(
          focusIndex: focusIndex!,
          fieldWidth: fieldWidth,
          fieldHeight: fieldHeight,
          gameSize: gameSize,
        ),
        size: gameSize,
      ),
    );
  }
}

class FocusOverlayPainter extends CustomPainter {
  final int focusIndex;
  final int fieldWidth;
  final int fieldHeight;
  final Size gameSize;

  FocusOverlayPainter({
    required this.focusIndex,
    required this.fieldWidth,
    required this.fieldHeight,
    required this.gameSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double tileWidth = gameSize.width / fieldWidth;
    final double tileHeight = gameSize.height / fieldHeight;

    // Calculate row and column of focus index
    final int focusRow = focusIndex ~/ fieldWidth;
    final int focusCol = focusIndex % fieldWidth;

    // Calculate 3x3 area (clamped to board bounds)
    final int startRow = (focusRow - 1).clamp(0, fieldHeight - 1);
    final int endRow = (focusRow + 1).clamp(0, fieldHeight - 1);
    final int startCol = (focusCol - 1).clamp(0, fieldWidth - 1);
    final int endCol = (focusCol + 1).clamp(0, fieldWidth - 1);

    // Convert to pixel coordinates
    final double cutoutX = startCol * tileWidth;
    final double cutoutY = startRow * tileHeight;
    final double cutoutWidth = (endCol - startCol + 1) * tileWidth;
    final double cutoutHeight = (endRow - startRow + 1) * tileHeight;

    // Create the overlay path with cutout
    final Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create the cutout path with rounded corners
    final double cornerRadius = 15.0;
    final RRect cutoutRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cutoutX, cutoutY, cutoutWidth, cutoutHeight),
      Radius.circular(cornerRadius),
    );
    final Path cutoutPath = Path()..addRRect(cutoutRRect);

    // Combine paths using even-odd rule to create the cutout
    final Path finalPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      cutoutPath,
    );

    // Draw the semi-transparent overlay
    final Paint paint = Paint()
      ..color = Colors.black.withAlpha(128)
      ..style = PaintingStyle.fill;

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(FocusOverlayPainter oldDelegate) {
    return oldDelegate.focusIndex != focusIndex ||
        oldDelegate.fieldWidth != fieldWidth ||
        oldDelegate.fieldHeight != fieldHeight ||
        oldDelegate.gameSize != gameSize;
  }
}
