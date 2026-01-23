import "dart:math";

import "package:another_mine/ai/guesser.dart";

abstract class RandomGuesser extends Guesser {
  final Random _random;

  const RandomGuesser(this._random, super.game);

  int nextRandom(int max) => _random.nextInt(max);
}
