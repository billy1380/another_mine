import "package:another_mine_common/another_mine_common.dart";
import "package:flutter/painting.dart";

/// Moves between the engine's [Colour] and Flutter's [Color].
extension ColourToColor on Colour {
  Color get color => Color(argb);
}

extension ColorToColour on Color {
  Colour get colour => Colour(toARGB32());
}

/// Moves between the engine's [BoardSize] and Flutter's [Size].
extension BoardSizeToSize on BoardSize {
  Size get size => Size(width, height);
}
