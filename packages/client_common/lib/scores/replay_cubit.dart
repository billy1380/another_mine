import "dart:async";

import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_common/logic/recorded_game_builder.dart";
import "package:another_mine_common/scores/recording.dart";
import "package:bloc/bloc.dart";
import "package:equatable/equatable.dart";
import "package:main_thread_processor/main_thread_processor.dart";

/// Where a replay has got to.
class ReplayState extends Equatable {
  /// How far through, in milliseconds of play (the time a recorded pause took
  /// beyond [ReplayCubit.pauseLimit] is skipped), and how long it all is.
  final int position;
  final int total;
  final bool playing;
  final double speed;

  /// Whether the player had probabilities, focus mode or the game paused at
  /// this point.
  final bool probability;
  final bool focus;
  final bool paused;

  const ReplayState({
    this.position = 0,
    this.total = 0,
    this.playing = false,
    this.speed = 1,
    this.probability = false,
    this.focus = false,
    this.paused = false,
  });

  bool get finished => position >= total;

  ReplayState copyWith({
    int? position,
    bool? playing,
    double? speed,
    bool? probability,
    bool? focus,
    bool? paused,
  }) => ReplayState(
    position: position ?? this.position,
    total: total,
    playing: playing ?? this.playing,
    speed: speed ?? this.speed,
    probability: probability ?? this.probability,
    focus: focus ?? this.focus,
    paused: paused ?? this.paused,
  );

  @override
  List<Object?> get props => [
    position,
    total,
    playing,
    speed,
    probability,
    focus,
    paused,
  ];
}

/// Plays a [Recording] on its own [GameBloc], built from the recorded mines,
/// by feeding it the player's moves on the recorded timeline, scaled by the
/// speed.
class ReplayCubit extends Cubit<ReplayState> {
  /// The longest a recorded pause is waited out; the rest is skipped.
  static const int pauseLimit = 1000;
  static const List<double> speeds = [1, 2, 4];

  final Recording recording;
  final GameBloc bloc;
  final List<({int at, ReplayEvent event})> _timeline;
  Timer? _timer;
  DateTime? _last;
  int _next = 0;

  ReplayCubit(this.recording, {Processor? processor})
    : bloc = GameBloc(
        processor: processor ?? Processor(),
        gameBuilder: RecordedGameBuilder(recording),
        remembersGames: false,
      ),
      _timeline = _lay(recording.events),
      super(const ReplayState()) {
    emit(ReplayState(total: _timeline.isEmpty ? 0 : _timeline.last.at));
  }

  static List<({int at, ReplayEvent event})> _lay(List<ReplayEvent> events) {
    final List<({int at, ReplayEvent event})> timeline = [];
    int skipped = 0;

    for (int i = 0; i < events.length; i++) {
      final ReplayEvent event = events[i];

      if (event.code == "resume" && i > 0 && events[i - 1].code == "pause") {
        final int gap = event.ms - events[i - 1].ms;
        if (gap > pauseLimit) skipped += gap - pauseLimit;
      }

      timeline.add((at: event.ms - skipped, event: event));
    }

    return timeline;
  }

  /// Sets the board up and, if [autoplay], plays from the start.
  Future<void> start({bool autoplay = true}) async {
    await _reset();
    if (autoplay) play();
  }

  void play() {
    if (state.finished) return;

    _last = DateTime.now();
    _timer ??= Timer.periodic(const Duration(milliseconds: 40), (_) => _tick());
    emit(state.copyWith(playing: true));
  }

  void pause() {
    _stop();
    emit(state.copyWith(playing: false));
  }

  void setSpeed(double speed) => emit(state.copyWith(speed: speed));

  Future<void> restart() async {
    _stop();
    await _reset();
    play();
  }

  /// Moves to [ms] of play, setting the board up again first if that is back.
  Future<void> seek(int ms) async {
    final bool playing = state.playing;

    if (ms < state.position) {
      _stop();
      await _reset();
    }

    advanceTo(ms);
    if (playing && !state.finished) play();
  }

  /// Feeds the game everything recorded up to [ms] of play that it has not
  /// been fed yet.
  void advanceTo(int ms) {
    ReplayState next = state.copyWith(
      position: ms < 0 ? 0 : (ms > state.total ? state.total : ms),
    );

    while (_next < _timeline.length && _timeline[_next].at <= next.position) {
      next = _feed(_timeline[_next].event, next);
      _next++;
    }

    if (next.finished) {
      _stop();
      next = next.copyWith(playing: false, paused: false);
    }

    emit(next);
  }

  ReplayState _feed(ReplayEvent event, ReplayState state) {
    switch (event.code) {
      case "p":
        bloc.add(Probe(model: bloc.state.tiles[event.argument!]));
      case "f":
        bloc.add(Speculate(model: bloc.state.tiles[event.argument!]));
      case "prob":
        if (bloc.state.showProbability != event.on) {
          bloc.add(const ToggleProbabilities());
        }
        return state.copyWith(probability: event.on);
      case "focus":
        if (bloc.state.isFocusMode != event.on) {
          bloc.add(const ToggleFocusMode());
        }
        return state.copyWith(focus: event.on);
      case "pause":
        return state.copyWith(paused: true);
      case "resume":
        return state.copyWith(paused: false);
    }

    return state;
  }

  Future<void> _reset() async {
    _next = 0;
    bloc.add(NewGame(difficulty: recording.gameDifficulty));
    // the new game is set up on the next turn of the event loop
    await Future<void>.delayed(Duration.zero);
    emit(ReplayState(total: state.total, speed: state.speed));
  }

  void _tick() {
    final DateTime now = DateTime.now();
    final int elapsed = now.difference(_last ?? now).inMilliseconds;

    _last = now;
    advanceTo(state.position + (elapsed * state.speed).round());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() async {
    _stop();
    await bloc.close();
    return super.close();
  }
}
