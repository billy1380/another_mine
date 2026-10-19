import "dart:async";

import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_web/services/local_storage_pref_storage.dart";
import "package:another_mine_web/ui/bloc_provider.dart";
import "package:another_mine_web/ui/screens/custom_game_screen.dart";
import "package:another_mine_web/ui/screens/game_screen.dart";
import "package:another_mine_web/ui/screens/scores_screen.dart";
import "package:another_mine_web/ui/screens/settings_screen.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";
import "package:main_thread_processor/main_thread_processor.dart";
import "package:willshex_embedding/willshex_embedding.dart";

/// Another Mine as a component that can be dropped into another Jaspr app.
///
/// Brings its own services and game state, so the host only has to give it some
/// space. No router, sidebar or header is involved; the host supplies the page
/// chrome and navigation between [AnotherMineSection]s, and can show the
/// game's title and actions in its own header through [session].
class AnotherMineWebView extends StatefulComponent {
  /// Which page to show.
  final AnotherMineSection section;

  /// The difficulty to play in [AnotherMineSection.game], or null to carry on
  /// with the last one played.
  final GameDifficulty? difficulty;

  /// Called once a custom difficulty has been chosen and saved, so that the
  /// host can go to the game.
  final void Function(GameDifficulty difficulty)? onCustomGameStarted;

  /// Called when the custom game dialog is dismissed without starting.
  final void Function()? onCustomGameCancelled;

  /// Where the title and actions of the game are published, for the host to
  /// show in its header.
  final PageSession? session;

  /// Where to keep settings. Defaults to the browser's `localStorage`.
  final PrefStorage? storage;

  const AnotherMineWebView({
    super.key,
    this.section = AnotherMineSection.game,
    this.difficulty,
    this.onCustomGameStarted,
    this.onCustomGameCancelled,
    this.session,
    this.storage,
  });

  @override
  State<AnotherMineWebView> createState() => _AnotherMineWebViewState();
}

class _AnotherMineWebViewState extends State<AnotherMineWebView> {
  GameBloc? _bloc;
  GameSessionPublisher? _publisher;
  StreamSubscription<GameState>? _subscription;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  @override
  void didUpdateComponent(AnotherMineWebView oldComponent) {
    super.didUpdateComponent(oldComponent);

    if (_plays(component.section) &&
        (!_plays(oldComponent.section) ||
            oldComponent.difficulty != component.difficulty)) {
      _startGame();
    }

    // A host that rebuilds this component whenever the header it shows changes
    // would otherwise loop: publishing changes the header, which rebuilds, which
    // publishes again. Only publish again when what is shown has changed.
    if (oldComponent.session != component.session) {
      final GameBloc? bloc = _bloc;
      final PageSession? session = component.session;
      _publisher = bloc == null || session == null
          ? null
          : GameSessionPublisher(bloc: bloc, session: session);
    }

    if (oldComponent.section != component.section ||
        oldComponent.session != component.session) {
      _publisher?.invalidate();
      _publish();
    }
  }

  static bool _plays(AnotherMineSection section) =>
      section == AnotherMineSection.game ||
      section == AnotherMineSection.custom;

  void _publish() => _publisher?.publish(component.section);

  void _startGame() {
    _bloc?.add(
      NewGame(difficulty: component.difficulty ?? Provider.pref.difficulty),
    );
  }

  Future<void> _initialise() async {
    try {
      await initServices(component.storage ?? LocalStoragePrefStorage());

      if (!mounted) return;

      final GameBloc bloc = GameBloc(processor: Processor.shared);
      final PageSession? session = component.session;

      _publisher = session == null
          ? null
          : GameSessionPublisher(bloc: bloc, session: session);
      _subscription = bloc.stream.listen((_) => _publish());
      setState(() => _bloc = bloc);

      if (_plays(component.section)) _startGame();
      _publish();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bloc?.close();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final GameBloc? bloc = _bloc;

    if (_error != null) {
      return div(classes: "p-4 text-center", [
        Component.text("Unable to start Another Mine: $_error"),
      ]);
    } else if (bloc == null) {
      return const div(classes: "p-4 text-center text-secondary", [
        Component.text("Loading..."),
      ]);
    }

    return BlocProvider<GameBloc>(
      bloc: bloc,
      child: switch (component.section) {
        AnotherMineSection.game => const GameView(),
        AnotherMineSection.custom => Component.fragment([
          const GameView(),
          CustomGameDialog(
            onStart: (difficulty) =>
                component.onCustomGameStarted?.call(difficulty),
            onCancel: () => component.onCustomGameCancelled?.call(),
          ),
        ]),
        AnotherMineSection.scores => const ScoresView(),
        AnotherMineSection.settings => const SettingsView(),
      },
    );
  }
}
