import "package:another_mine/bloc/game/game_bloc.dart";

abstract class Guesser {
  final GameBloc game;

  const Guesser(this.game);

  void makeAMove();
}
