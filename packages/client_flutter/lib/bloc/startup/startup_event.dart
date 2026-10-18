part of "startup_bloc.dart";

abstract class StartupEvent extends Equatable {
  const StartupEvent();

  @override
  List<Object> get props => [];
}

class InitializeApp extends StartupEvent {
  const InitializeApp();
}
