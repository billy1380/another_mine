import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_web/routes.dart";
import "package:another_mine_web/services/local_storage_pref_storage.dart";
import "package:another_mine_web/ui/bloc_provider.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";
import "package:jaspr_router/jaspr_router.dart";
import "package:main_thread_processor/main_thread_processor.dart";

/// Another Mine as a web app.
class App extends StatefulComponent {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  GameBloc? _bloc;
  Router? _router;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  Future<void> _initialise() async {
    try {
      await initServices(LocalStoragePrefStorage());

      if (!mounted) return;
      setState(() {
        _bloc = GameBloc(processor: Processor.shared);
        _router = Router(routes: AnotherMineWebRoutes.routes());
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _bloc?.close();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final GameBloc? bloc = _bloc;
    final Router? router = _router;

    if (_error != null) {
      return div(classes: "p-4 text-center", [
        Component.text("Unable to start Another Mine: $_error"),
      ]);
    } else if (bloc == null || router == null) {
      return const div(classes: "p-4 text-center text-secondary", [
        Component.text("Loading..."),
      ]);
    }

    return BlocProvider<GameBloc>(bloc: bloc, child: router);
  }
}
