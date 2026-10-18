import "package:flutter/widgets.dart";

/// Where Another Mine's bundled images are looked up.
abstract class AnotherMineAssets {
  /// The package the images are bundled in.
  ///
  /// Null when running as the app itself. Set to `another_mine` when used from
  /// another app, which bundles the images under `packages/another_mine/`.
  static String? package;

  static Image image(String name, {double? height}) =>
      Image.asset(name, package: package, height: height);
}
