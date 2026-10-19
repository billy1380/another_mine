import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/services/shared_preferences_pref_storage.dart";
import "package:bloc/bloc.dart";
import "package:equatable/equatable.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:willshex/willshex.dart";

part "startup_event.dart";
part "startup_state.dart";

class StartupBloc extends Bloc<StartupEvent, StartupState> {
  static final Logger _log = Logger("StartupBloc");

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

      await initServices(SharedPreferencesPrefStorage());

      emit(state.copyWith(status: StartupStatus.complete));
    } catch (e, st) {
      _log.severe("Startup failed to initialise", e, st);
      emit(state.copyWith(status: StartupStatus.error, error: e));
    }
  }
}
