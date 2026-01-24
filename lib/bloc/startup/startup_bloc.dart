import "package:another_mine/services/registrar.dart";
import "package:bloc/bloc.dart";
import "package:equatable/equatable.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:willshex/willshex.dart";

part "startup_event.dart";
part "startup_state.dart";

class StartupBloc extends Bloc<StartupEvent, StartupState> {
  StartupBloc() : super(const StartupState()) {
    on<InitializeApp>(_onInitializeApp);
  }

  Future<void> _onInitializeApp(
    InitializeApp event,
    Emitter<StartupState> emit,
  ) async {
    if (state.status == StartupStatus.complete) return;

    emit(state.copyWith(status: StartupStatus.loading));

    try {
      setupLogging();

      if (kIsWeb) {
        await BrowserContextMenu.disableContextMenu();
      }

      await Registrar.init();

      emit(state.copyWith(status: StartupStatus.complete));
    } catch (e) {
      emit(state.copyWith(status: StartupStatus.error, error: e));
    }
  }
}
