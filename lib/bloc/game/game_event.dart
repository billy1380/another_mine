part of "game_bloc.dart";

@immutable
sealed class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

@immutable
class ToggleAutoSolver extends GameEvent {
  const ToggleAutoSolver();
}

@immutable
class NewGame extends GameEvent {
  final GameDifficulty difficulty;

  const NewGame({
    required this.difficulty,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        difficulty,
      ];
}

@immutable
class Probe extends GameEvent {
  final TileModel model;

  const Probe({
    required this.model,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        model,
      ];
}

@immutable
class Speculate extends GameEvent {
  final TileModel model;

  const Speculate({
    required this.model,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        model,
      ];
}

@immutable
class MightPlay extends GameEvent {
  final TileModel model;

  const MightPlay({
    required this.model,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        model,
      ];
}

@immutable
class DonePlaying extends GameEvent {
  const DonePlaying();
}

class RevealAll extends GameEvent {
  const RevealAll();
}

class AutoSolverNextMove extends GameEvent {
  const AutoSolverNextMove();
}

class PauseAutoSolver extends GameEvent {
  const PauseAutoSolver();
}

class ResumeAutoSolver extends GameEvent {
  const ResumeAutoSolver();
}

class PauseGame extends GameEvent {
  const PauseGame();
}

class ResumeGame extends GameEvent {
  const ResumeGame();
}
