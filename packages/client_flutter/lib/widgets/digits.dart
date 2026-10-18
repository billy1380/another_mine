import "package:another_mine_common/presentation/presentation.dart";
import "package:another_mine_flutter/assets.dart";
import "package:flutter/material.dart";
import "package:mine_images/mine_images.dart";

class Digits extends StatelessWidget {
  final String name;
  final int value;
  final int digits;
  final Color backgroundColor;

  const Digits({
    super.key,
    required this.name,
    required this.value,
    this.digits = 2,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      child: Container(
        height: 48,
        width: ((digits * 25) + 16).toDouble(),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        child: Stack(
          children: [
            ..._digits(),
            Container(
              width: (digits * 45).toDouble(),
              height: 20,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                color: Color(0x30FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _digits() {
    final List<MineImage> images = counterImages(value, digits: digits);

    return [
      for (int i = 0; i < images.length; i++)
        Positioned(
          left: (25 * i).toDouble(),
          child: AnotherMineAssets.image(images[i], height: 50),
        ),
    ];
  }
}
