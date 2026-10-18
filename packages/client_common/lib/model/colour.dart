import "dart:math";

/// An ARGB colour that does not depend on any UI framework.
///
/// Held as the same 32 bit `0xAARRGGBB` value that Flutter's `Color` uses, so
/// the Flutter client can convert with `Color(colour.argb)`.
extension type const Colour(int argb) {
  const Colour.fromARGB(int a, int r, int g, int b)
    : this(
        ((a & 0xff) << 24) |
            ((r & 0xff) << 16) |
            ((g & 0xff) << 8) |
            (b & 0xff),
      );

  int get alpha => (argb >> 24) & 0xff;
  int get red => (argb >> 16) & 0xff;
  int get green => (argb >> 8) & 0xff;
  int get blue => argb & 0xff;

  Colour withAlpha(int a) => Colour.fromARGB(a, red, green, blue);

  /// The same colour with a different alpha, scaled from `0.0` to `1.0`.
  Colour withOpacity(double opacity) =>
      withAlpha((opacity.clamp(0.0, 1.0) * 255).round());

  /// The relative luminance, `0.0` (black) to `1.0` (white).
  double computeLuminance() =>
      0.2126 * _linear(red) + 0.7152 * _linear(green) + 0.0722 * _linear(blue);

  /// The colour as `#rrggbb` for use in CSS.
  String get hex => "#${(argb & 0xffffff).toRadixString(16).padLeft(6, "0")}";

  /// The colour as a CSS `rgba(...)` value.
  String get css =>
      "rgba($red, $green, $blue, ${(alpha / 255).toStringAsFixed(3)})";

  static double _linear(int component) {
    final double c = component / 255.0;
    return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }
}
