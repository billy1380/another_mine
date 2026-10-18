import "dart:async";

import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/extensions/colour_ex.dart";
import "package:another_mine_flutter/pages/settings_page.dart";
import "package:another_mine_flutter/services/shared_preferences_pref_storage.dart";
import "package:another_mine_flutter/widgets/custom_game_form.dart";
import "package:another_mine_flutter/widgets/game_body.dart";
import "package:another_mine_flutter/widgets/game_tools_menu.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:main_thread_processor/main_thread_processor.dart";
import "package:willshex/willshex.dart";
import "package:willshex_embedding/willshex_embedding.dart";

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
  void didUpdateWidget(AnotherMineView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.section == AnotherMineSection.game &&
        (oldWidget.section != widget.section ||
            oldWidget.difficulty != widget.difficulty)) {
      _startGame();
    }

    // A host that rebuilds this widget whenever the header it shows changes
    // would otherwise loop: publishing changes the header, which rebuilds, which
    // publishes again. Only publish again when what is shown has changed.
    if (oldWidget.session != widget.session) {
      final GameBloc? bloc = _bloc;
      final PageSession? session = widget.session;
      _publisher = bloc == null || session == null
          ? null
          : GameSessionPublisher(bloc: bloc, session: session);
    }

    if (oldWidget.section != widget.section ||
        oldWidget.session != widget.session) {
      _publisher?.invalidate();
      _publish();
    }
  }

  /// Gives the host the title and actions for the current game.
  void _publish() => _publisher?.publish(widget.section);

  void _startGame() {
    _bloc?.add(
      NewGame(difficulty: widget.difficulty ?? Provider.pref.difficulty),
    );
  }

  /// Shows or hides the browser's context menu. Only the app's main view can,
  /// so it is left alone, quietly, anywhere else (such as a view embedded in a
  /// page that is not Flutter).
  Future<void> _setContextMenu({required bool enabled}) async {
    if (!kIsWeb) return;

    try {
      await (enabled
          ? BrowserContextMenu.enableContextMenu()
          : BrowserContextMenu.disableContextMenu());
    } catch (_) {}
  }

  Future<void> _initialise() async {
    try {
      await initServices(SharedPreferencesPrefStorage());

      // Flags are set with a secondary click.
      await _setContextMenu(enabled: false);

      if (!mounted) return;

      final GameBloc bloc = GameBloc(processor: Processor.shared);
      final PageSession? session = widget.session;

      _publisher = session == null
          ? null
          : GameSessionPublisher(bloc: bloc, session: session);
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
    _setContextMenu(enabled: true);
    _subscription?.cancel();
    _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Another Mine",
      theme:
          widget.theme ??
          ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Pref.defaultBackgroundColour.color,
            ),
            useMaterial3: true,
          ),
      home: Scaffold(body: _buildBody()),
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
