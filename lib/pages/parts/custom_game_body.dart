import "package:flutter/material.dart";

class CustomGameBody extends StatelessWidget {
  static const int minWidth = 5;
  static const int maxWidth = 50;
  static const int minHeight = 5;
  static const int maxHeight = 50;

  final int width;
  final int height;
  final int mines;
  final int maxMines;
  final ValueChanged<int> onWidthChanged;
  final ValueChanged<int> onHeightChanged;
  final ValueChanged<int> onMinesChanged;

  const CustomGameBody({
    super.key,
    required this.width,
    required this.height,
    required this.mines,
    required this.maxMines,
    required this.onWidthChanged,
    required this.onHeightChanged,
    required this.onMinesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Width"),
          Row(
            children: [
              const Text("$minWidth"),
              Expanded(
                child: Slider(
                  value: width.toDouble(),
                  min: minWidth.toDouble(),
                  max: maxWidth.toDouble(),
                  divisions: maxWidth - minWidth,
                  label: width.toString(),
                  onChanged: (value) => onWidthChanged(value.toInt()),
                ),
              ),
              const Text("$maxWidth"),
            ],
          ),
          Text("Current Width: $width"),
          const SizedBox(height: 16),
          const Text("Height"),
          Row(
            children: [
              const Text("$minHeight"),
              Expanded(
                child: Slider(
                  value: height.toDouble(),
                  min: minHeight.toDouble(),
                  max: maxHeight.toDouble(),
                  divisions: maxHeight - minHeight,
                  label: height.toString(),
                  onChanged: (value) => onHeightChanged(value.toInt()),
                ),
              ),
              const Text("$maxHeight"),
            ],
          ),
          Text("Current Height: $height"),
          const SizedBox(height: 16),
          const Text("Mines"),
          Row(
            children: [
              const Text("1"),
              Expanded(
                child: Slider(
                  value: mines.toDouble(),
                  min: 1,
                  max: maxMines.toDouble(),
                  divisions: maxMines > 1 ? maxMines - 1 : 1,
                  label: mines.toString(),
                  onChanged: (value) => onMinesChanged(value.toInt()),
                ),
              ),
              Text("$maxMines"),
            ],
          ),
          Text("Current Mines: $mines"),
        ],
      ),
    );
  }
}
