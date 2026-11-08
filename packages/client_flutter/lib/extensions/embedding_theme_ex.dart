import "package:flutter/material.dart";
import "package:willshex_embedding/willshex_embedding.dart";

extension EmbeddingThemeEx on EmbeddingTheme {
  /// Material widgets in the host's colours, light or dark as its background is.
  ThemeData toThemeData() {
    final Color primary = Color(primaryColor);
    final Color surface = Color(surfaceColor);
    final Color onSurface = Color(onSurfaceColor);
    final Color divider = Color(dividerColor);
    final Brightness brightness = ThemeData.estimateBrightnessForColor(
      Color(backgroundColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: primary,
            brightness: brightness,
          ).copyWith(
            primary: primary,
            onPrimary:
                ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
                ? Colors.white
                : Colors.black,
            surface: surface,
            onSurface: onSurface,
            outline: divider,
            outlineVariant: divider,
            secondaryContainer: Color.alphaBlend(
              primary.withValues(alpha: 0.2),
              surface,
            ),
            onSecondaryContainer: primary,
          ),
      sliderTheme: SliderThemeData(inactiveTrackColor: divider),
      dividerTheme: DividerThemeData(color: divider, thickness: lineWidth),
    );
  }
}
