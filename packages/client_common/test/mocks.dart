import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_common/services/pref.dart";
import "package:mocktail/mocktail.dart";

class MockGameBloc extends Mock implements GameBloc {}

class FakePref extends Mock implements Pref {}

class FakeProbe extends Fake implements Probe {}

class FakeSpeculate extends Fake implements Speculate {}
