import "dart:async";

import "package:another_mine/assets.dart";
import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/pages/settings_page.dart";
import "package:another_mine/services/pref.dart";
import "package:another_mine/services/provider.dart";
import "package:another_mine/strings.dart";
import "package:another_mine/widgets/custom_game_form.dart";
import "package:another_mine/widgets/game_body.dart";
import "package:another_mine/widgets/game_tools_menu.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:main_thread_processor/main_thread_processor.dart";
import "package:willshex/willshex.dart";
import "package:willshex_dart_service_discovery/willshex_dart_service_discovery.dart";
import "package:willshex_embedding/willshex_embedding.dart";

/// The pages of Another Mine that a host can show.
///
/// What the game's own drawer offered, split out so that a host can list them
/// as sub pages.
enum AnotherMineSection {
  /// Playing. The difficulty is the one passed in or else the last one played.
  game,

  /// Choose a custom board size and mine count.
  custom,

  /// High scores.
  scores,

  /// Game settings.
  settings,
}

/// Another Mine as a widget that can be dropped into another app (Flutter, or
/// a Jaspr page through a Flutter embed view).
///
/// Brings its own material app, services and game state, so the host only has
/// to give it some space. No router, scaffold or drawer is involved; the host
/// supplies the page chrome and navigation between [AnotherMineSection]s.
class AnotherMineView extends StatefulWidget {
  const AnotherMineView({
    super.key,
    this.section = AnotherMineSection.game,
    this.difficulty,
    this.onCustomGameStarted,
    this.session,
    this.theme,
  });

  /// Which page to show.
  final AnotherMineSection section;

  /// The difficulty to play in [AnotherMineSection.game], or null to carry on
  /// with the last one played.
  final GameDifficulty? difficulty;

  /// Called once a custom difficulty has been chosen and saved, so that the
  /// host can go to the game.
  final VoidCallback? onCustomGameStarted;

  /// Where the title and actions of the game are published, for the host to
  /// show in its header. Without one the game shows its own header.
  final PageSession? session;

  /// Overrides the default theme.
  final ThemeData? theme;

  @override
  State<AnotherMineView> createState() => _AnotherMineViewState();
}

class _AnotherMineViewState extends State<AnotherMineView> {
  static const String _prefPrefix = "another_mine_";

  GameBloc? _bloc;
  StreamSubscription<GameState>? _subscription;
  Object? _error;

  // what the published title and actions were last built from
  Object? _publishedFor;

  @override
  void initState() {
    super.initState();
    // The images are bundled with this package, not with the host app.
    AnotherMineAssets.package = "another_mine";
    _initialise();
  }

  @override
  void didUpdateWidget(AnotherMineView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.section == AnotherMineSection.game &&
        (oldWidget.section != widget.section ||
            oldWidget.difficulty != widget.difficulty)) {
      _startGame();
    }

    _publishedFor = null;
    _publish();
  }

  /// Gives the host the title and actions for the current game.
  void _publish() {
    final PageSession? session = widget.session;
    final GameBloc? bloc = _bloc;
    if (session == null || bloc == null) return;

    if (widget.section != AnotherMineSection.game) {
      if (_publishedFor != widget.section) {
        _publishedFor = widget.section;
        session.clearTitle();
        session.setActions(const []);
      }
      return;
    }

    final GameState state = bloc.state;
    final GameDifficulty difficulty = state.difficulty;
    // No game yet
    if (difficulty == GameDifficulty.none) return;

    // The state changes with every move and tick, the header only with these.
    final Object signature = (
      difficulty,
      state.status,
      state.autoSolverEnabled,
      state.autoSolverPaused,
      state.showProbability,
      state.isFocusMode,
    );
    if (signature == _publishedFor) return;
    _publishedFor = signature;

    final bool finished = state.status == GameStateType.won;

    PageAction toggle(String id, String label, bool on, VoidCallback onTrigger,
            double order) =>
        PageAction(
          id: id,
          label: label,
          variant: on ? ActionVariant.primary : ActionVariant.outline,
          isEnabled: !finished,
          order: order,
          onTrigger: onTrigger,
        );

    session.setTitle(
      "${StringUtils.upperCaseFirstLetter(difficulty.name)} - ${difficulty.description}",
      subtitle: "Another Mine",
    );
    session.setActions([
      toggle(
        "solver",
        Strings.autoSolver,
        state.autoSolverEnabled,
        () => bloc.add(const ToggleAutoSolver()),
        1,
      ),
      toggle(
        "probability",
        Strings.probabilities,
        state.showProbability,
        () => bloc.add(const ToggleProbabilities()),
        2,
      ),
      toggle(
        "focus",
        Strings.focusMode,
        state.isFocusMode,
        () => bloc.add(const ToggleFocusMode()),
        3,
      ),
      if (state.autoSolverEnabled)
        PageAction(
          id: "solver_pause",
          label: state.autoSolverPaused ? "Resume solver" : "Pause solver",
          order: 4,
          onTrigger: () => bloc.add(
            state.autoSolverPaused
                ? const ResumeAutoSolver()
                : const PauseAutoSolver(),
          ),
        ),
    ]);
  }

  void _startGame() {
    _bloc?.add(
      NewGame(difficulty: widget.difficulty ?? Provider.pref.difficulty),
    );
  }

  Future<void> _initialise() async {
    try {
      // Only this game's own service, other services in the discovery
      // registry belong to the host and are left alone.
      final ServiceDiscovery discovery = ServiceDiscovery.instance;
      if (!discovery.isRegistered<Pref>()) {
        discovery.register<Pref>(Pref(_prefPrefix));
      }
      await discovery.resolve<Pref>().init();

      if (kIsWeb) {
        // Flags are set with a secondary click.
        await BrowserContextMenu.disableContextMenu();
      }

      if (!mounted) return;

      final GameBloc bloc = GameBloc(processor: Processor.shared);

      _subscription = bloc.stream.listen((_) => _publish());
      setState(() => _bloc = bloc);

      if (widget.section == AnotherMineSection.game) _startGame();
      _publish();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      BrowserContextMenu.enableContextMenu();
    }
    _subscription?.cancel();
    _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Another Mine",
      theme: widget.theme ??
          ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Pref.defaultBackgroundColour,
            ),
            useMaterial3: true,
          ),
      home: Scaffold(
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final GameBloc? bloc = _bloc;

    if (_error != null) {
      return Center(child: Text("Unable to start Another Mine\n$_error"));
    } else if (bloc == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocProvider<GameBloc>.value(
      value: bloc,
      child: switch (widget.section) {
        AnotherMineSection.game => Column(
            children: [
              if (widget.session == null) const _Header(),
              const Expanded(child: GameBody()),
            ],
          ),
        AnotherMineSection.custom => CustomGameForm(
            onStart: (_) => widget.onCustomGameStarted?.call(),
          ),
        AnotherMineSection.scores => const Center(
            child: Text("Scores are not available yet."),
          ),
        AnotherMineSection.settings => const SettingsPage.embedded(),
      },
    );
  }
}

/// The current difficulty and the game tools, like the game's own app bar.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      buildWhen: (a, b) => a.difficulty != b.difficulty,
      builder: (context, state) {
        final GameDifficulty difficulty = state.difficulty;

        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "${StringUtils.upperCaseFirstLetter(difficulty.name)} - ${difficulty.description}",
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const GameToolsMenu(),
            ],
          ),
        );
      },
    );
  }
}
