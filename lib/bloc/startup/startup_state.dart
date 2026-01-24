part of "startup_bloc.dart";

enum StartupStatus { initial, loading, complete, error }

class StartupState extends Equatable {
  final StartupStatus status;
  final Object? error;

  const StartupState({
    this.status = StartupStatus.initial,
    this.error,
  });

  StartupState copyWith({
    StartupStatus? status,
    Object? error,
  }) {
    return StartupState(
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  bool get isInitialized => status == StartupStatus.complete;

  @override
  List<Object?> get props => [status, error];
}
