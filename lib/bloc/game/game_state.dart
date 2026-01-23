part of "game_bloc.dart";

@immutable
final class GameState extends Equatable {
  final GameDifficulty difficulty;
  final GameStateType status;
  final GameStateType previousStatus;
  final List<TileModel> tiles;
  final DateTime? start, end;
  final int minesMarked;
  final int revealedTiles;
  final Color colour;
  final bool autoSolverEnabled;
  final int refresh;
  final bool autoSolverPaused;
  final Size gameSize;
  final Duration accumulatedDuration;
  final DateTime? lastActiveTime;
  final List<double> mineProbabilities;

  final int? lastInteractedIndex;
  final bool showProbability;
  final bool isFocusMode;

  const GameState._({
    required this.difficulty,
    required this.status,
    required this.previousStatus,
    required this.tiles,
    required this.start,
    required this.end,
    required this.minesMarked,
    required this.revealedTiles,
    required this.colour,
    required this.autoSolverEnabled,
    required this.refresh,
    required this.autoSolverPaused,
    required this.gameSize,
    required this.accumulatedDuration,
    required this.lastActiveTime,
    required this.mineProbabilities,
    required this.lastInteractedIndex,
    required this.showProbability,
    required this.isFocusMode,
  });

  factory GameState.initial(
    GameDifficulty difficulty,
    Color colour, [
    GameBuilder? builder,
  ]) {
    return GameState._(
      gameSize: Size(
        difficulty.width * mineDim,
        difficulty.height * mineDim,
      ),
      autoSolverEnabled: false,
      difficulty: difficulty,
      colour: colour,
      end: null,
      start: null,
      minesMarked: 0,
      revealedTiles: 0,
      status: GameStateType.notStarted,
      previousStatus: GameStateType.notStarted,
      tiles: (builder ?? RandomGameBuilder()).build(
        difficulty,
        colour,
      ),
      refresh: 0,
      autoSolverPaused: false,
      accumulatedDuration: Duration.zero,
      lastActiveTime: null,
      mineProbabilities: List.filled(
        difficulty.area,
        difficulty.mines / difficulty.area,
      ),
      lastInteractedIndex: null,
      showProbability: false,
      isFocusMode: false,
    );
  }

  GameState copyWith({
    GameDifficulty? difficulty,
    GameStateType? status,
    GameStateType? previousStatus,
    List<TileModel>? tiles,
    DateTime? start,
    bool clearStart = false,
    DateTime? end,
    bool clearEnd = false,
    int? minesMarked,
    int? revealedTiles,
    Color? colour,
    bool? autoSolverEnabled,
    int? refresh,
    bool? autoSolverPaused,
    Size? gameSize,
    Duration? accumulatedDuration,
    DateTime? lastActiveTime,
    bool clearLastActiveTime = false,
    List<double>? mineProbabilities,
    int? lastInteractedIndex,
    bool? showProbability,
    bool? isFocusMode,
  }) =>
      GameState._(
        difficulty: difficulty ?? this.difficulty,
        status: status ?? this.status,
        previousStatus: previousStatus ?? this.previousStatus,
        tiles: tiles ?? this.tiles,
        start: clearStart ? null : start ?? this.start,
        end: clearEnd ? null : end ?? this.end,
        minesMarked: minesMarked ?? this.minesMarked,
        revealedTiles: revealedTiles ?? this.revealedTiles,
        colour: colour ?? this.colour,
        autoSolverEnabled: autoSolverEnabled ?? this.autoSolverEnabled,
        refresh: refresh ?? this.refresh,
        autoSolverPaused: autoSolverPaused ?? this.autoSolverPaused,
        gameSize: gameSize ?? this.gameSize,
        accumulatedDuration: accumulatedDuration ?? this.accumulatedDuration,
        lastActiveTime:
            clearLastActiveTime ? null : lastActiveTime ?? this.lastActiveTime,
        mineProbabilities: mineProbabilities ?? this.mineProbabilities,
        lastInteractedIndex: lastInteractedIndex ?? this.lastInteractedIndex,
        showProbability: showProbability ?? this.showProbability,
        isFocusMode: isFocusMode ?? this.isFocusMode,
      );

  @override
  List<Object?> get props => [
        difficulty,
        status,
        previousStatus,
        ...tiles,
        start,
        end,
        minesMarked,
        revealedTiles,
        colour,
        autoSolverEnabled,
        refresh,
        autoSolverPaused,
        accumulatedDuration,
        lastActiveTime,
        ...mineProbabilities,
        lastInteractedIndex,
        showProbability,
        isFocusMode,
      ];

  bool get isFinished =>
      status == GameStateType.won || status == GameStateType.lost;
  bool get isNotFinished => !isFinished;

  int get seconds {
    if (isFinished) {
      return accumulatedDuration.inSeconds;
    }

    int duration = accumulatedDuration.inSeconds;

    if (lastActiveTime != null) {
      duration += DateTime.now().difference(lastActiveTime!).inSeconds;
    }

    return duration;
  }

  TileModel? tileAt(int x, int y) =>
      status != GameStateType.lost && status != GameStateType.won
          ? tiles[(y * difficulty.width) + x]
          : null;
}
