import "dart:async";
import "package:another_mine/bloc/game/game_bloc.dart";
import "package:main_thread_processor/main_thread_processor.dart";
import "package:mocktail/mocktail.dart";

class MockGameBloc extends Mock implements GameBloc {}

class FakeProbe extends Fake implements Probe {}

class FakeSpeculate extends Fake implements Speculate {}

class FakeProcessor extends Fake implements Processor {
  @override
  void removeAllTasks() {}

  @override
  void pause() {}

  @override
  void resume() {}

  @override
  void addTask(Task task) {
    Timer(Duration.zero, () => task.run());
  }
}
