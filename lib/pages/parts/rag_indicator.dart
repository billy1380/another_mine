import "package:flutter/material.dart";

enum RagOrientation { row, column }

class RagIndicator extends StatelessWidget {
  final double value;
  final double thresholdToAmber;
  final double thresholdToRed;
  final RagOrientation orientation;

  const RagIndicator({
    this.orientation = RagOrientation.column,
    required this.value,
    required this.thresholdToAmber,
    required this.thresholdToRed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return orientation == RagOrientation.row
        ? Row(children: _children())
        : Column(children: _children());
  }

  List<Widget> _children() {
    return [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value < thresholdToAmber ? Colors.green : Colors.grey.shade300,
        ),
      ),
      orientation == RagOrientation.column
          ? const SizedBox(height: 4)
          : const SizedBox(width: 4),
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value >= thresholdToAmber && value < thresholdToRed
              ? Colors.orange
              : Colors.grey.shade300,
        ),
      ),
      orientation == RagOrientation.column
          ? const SizedBox(height: 4)
          : const SizedBox(width: 4),
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value >= thresholdToRed ? Colors.red : Colors.grey.shade300,
        ),
      ),
    ];
  }
}
