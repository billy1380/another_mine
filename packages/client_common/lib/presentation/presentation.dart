import "dart:math";

import "package:another_mine_common/model/colour.dart";
import "package:another_mine_common/model/game_state_type.dart";
import "package:another_mine_common/model/tile_state_type.dart";
import "package:mine_images/mine_images.dart";

/// The background of the tile that was detonated.
const Colour detonatedColour = Colour.fromARGB(0xFF, 0xE2, 0x41, 0x00);

/// The image drawn on a tile, or null when it is drawn as a plain tile (not
/// yet pressed, or revealed with no neighbouring mines).
MineImage? tileImage(TileStateType state) => switch (state) {
  TileStateType.detenateBomb => MineImage.dead,
  TileStateType.eight => MineImage.eight,
  TileStateType.five => MineImage.five,
  TileStateType.four => MineImage.four,
  TileStateType.one => MineImage.one,
  TileStateType.predictedBombCorrect => MineImage.found,
  TileStateType.predictedBombIncorrect => MineImage.not,
  TileStateType.revealedBomb => MineImage.hidden,
  TileStateType.seven => MineImage.seven,
  TileStateType.six => MineImage.six,
  TileStateType.three => MineImage.three,
  TileStateType.two => MineImage.two,
  TileStateType.unsure => MineImage.dunno,
  _ => null,
};

/// The face on the new game button.
MineImage faceImage(GameStateType state) => switch (state) {
  GameStateType.lost => MineImage.restin,
  GameStateType.won => MineImage.cool,
  GameStateType.thinking => MineImage.thinking,
  _ => MineImage.well,
};

/// The counter images for [value], most significant digit first, padded or cut
/// to [digits] places.
List<MineImage> counterImages(int value, {int digits = 2}) => [
  for (int position = digits; position > 0; position--)
    MineImage.counter(_digit(value, position)) ?? MineImage.counter0,
];

int _digit(int number, int position) =>
    (number % pow(10, position).toInt()) ~/ pow(10, position - 1);

/// Whether the probability of a mine is drawn over a tile in [state].
bool showsProbability(TileStateType state, double? probability) =>
    probability != null &&
    probability >= 0.01 &&
    (state == TileStateType.notPressed || state == TileStateType.unsure);

const Colour _green = Colour(0xFF4CAF50);
const Colour _orange = Colour(0xFFFF9800);
const Colour _red = Colour(0xFFF44336);

/// The colour of the probability label: green through orange to red as the
/// chance of a mine grows, lightened or darkened to stay readable on [tile].
Colour probabilityColour(double probability, Colour tile) {
  final Colour base = probability <= 0.5
      ? _lerp(_green, _orange, probability * 2)
      : _lerp(_orange, _red, (probability - 0.5) * 2);

  final bool darkBackground = tile.computeLuminance() < 0.5;

  return _withLightness(base, darkBackground ? 0.65 : 0.35);
}

/// The shadow behind the probability label, the opposite of the tile's tone.
Colour probabilityShadow(Colour tile) => tile.computeLuminance() > 0.5
    ? const Colour.fromARGB(204, 255, 255, 255)
    : const Colour.fromARGB(204, 0, 0, 0);

Colour _lerp(Colour a, Colour b, double t) {
  final double f = t.clamp(0.0, 1.0);
  int mix(int x, int y) => (x + (y - x) * f).round();
  return Colour.fromARGB(
    mix(a.alpha, b.alpha),
    mix(a.red, b.red),
    mix(a.green, b.green),
    mix(a.blue, b.blue),
  );
}

Colour _withLightness(Colour c, double lightness) {
  final double r = c.red / 255, g = c.green / 255, b = c.blue / 255;
  final double maxC = max(r, max(g, b)), minC = min(r, min(g, b));
  final double delta = maxC - minC;

  double hue = 0;
  if (delta != 0) {
    if (maxC == r) {
      hue = 60 * (((g - b) / delta) % 6);
    } else if (maxC == g) {
      hue = 60 * (((b - r) / delta) + 2);
    } else {
      hue = 60 * (((r - g) / delta) + 4);
    }
  }

  final double l = (maxC + minC) / 2;
  final double saturation = delta == 0 ? 0 : delta / (1 - (2 * l - 1).abs());

  final double chroma = (1 - (2 * lightness - 1).abs()) * saturation;
  final double x = chroma * (1 - ((hue / 60) % 2 - 1).abs());
  final double m = lightness - chroma / 2;

  final (double, double, double) rgb = switch (hue) {
    < 60 => (chroma, x, 0),
    < 120 => (x, chroma, 0),
    < 180 => (0, chroma, x),
    < 240 => (0, x, chroma),
    < 300 => (x, 0, chroma),
    _ => (chroma, 0, x),
  };

  int channel(double v) => ((v + m) * 255).round().clamp(0, 255);
  return Colour.fromARGB(
    c.alpha,
    channel(rgb.$1),
    channel(rgb.$2),
    channel(rgb.$3),
  );
}
