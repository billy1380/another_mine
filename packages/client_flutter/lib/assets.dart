import "package:flutter/widgets.dart";
import "package:mine_images/mine_images.dart";

/// Where Another Mine's bundled images are looked up.
///
/// The images are bundled in the `mine_images` package, so they are the same
/// whether the game runs as an app or inside another app.
abstract class AnotherMineAssets {
  static Image image(MineImage image, {double? height}) =>
      Image.asset(image.asset, package: MineImage.package, height: height);

  static bool _precached = false;

  /// Loads and decodes every image, so that none is fetched or decoded the
  /// first time a tile, a digit or a face shows it, which is seen as a lag.
  /// Done once, as the images stay in the image cache.
  static Future<void> precache(BuildContext context) {
    if (_precached) return Future.value();

    _precached = true;

    return Future.wait([
      for (final image in MineImage.values)
        precacheImage(
          AssetImage(image.asset, package: MineImage.package),
          context,
        ),
    ]);
  }
}
