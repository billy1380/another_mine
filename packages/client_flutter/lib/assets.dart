import "package:flutter/widgets.dart";
import "package:mine_images/mine_images.dart";

/// Where Another Mine's bundled images are looked up.
///
/// The images are bundled in the `mine_images` package, so they are the same
/// whether the game runs as an app or inside another app.
abstract class AnotherMineAssets {
  static Image image(MineImage image, {double? height}) =>
      Image.asset(image.asset, package: MineImage.package, height: height);
}
