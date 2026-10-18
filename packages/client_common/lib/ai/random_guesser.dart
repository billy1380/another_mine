import "dart:math";

import "package:another_mine_common/ai/guesser.dart";

abstract class RandomGuesser extends Guesser {
  final Random _random;
  const RandomGuesser(this._random);

  int nextRandom(int max) => _random.nextInt(max);
}
