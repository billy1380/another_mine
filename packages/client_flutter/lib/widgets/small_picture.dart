import "package:flutter/material.dart";
import "package:willshex_embedding/willshex_embedding.dart";

/// A [DialogImage] drawn small, with its label as the tooltip (hover, or press
/// and hold).
class SmallPicture extends StatelessWidget {
  final DialogImage image;
  final double height;

  const SmallPicture(this.image, {super.key, this.height = 18});

  @override
  Widget build(BuildContext context) {
    final Widget picture = ClipRRect(
      borderRadius: BorderRadius.circular(height >= 32 ? 8 : 3),
      child: Image.asset(
        image.asset,
        package: image.package,
        height: height,
        fit: BoxFit.contain,
        filterQuality: image.crisp ? FilterQuality.none : FilterQuality.low,
      ),
    );

    return image.label == null
        ? picture
        : Tooltip(message: image.label!, child: picture);
  }
}
