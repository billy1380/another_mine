import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/extensions/colour_ex.dart";
import "package:another_mine_flutter/widgets/game_body.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// The mine count, new game button, timer and minefield, for a page that is
/// not Flutter (a Jaspr page through a Flutter embed view).
///
/// The page keeps the [bloc], so its own sidebar and header can follow the
/// game, and this draws the playing area with the same widgets the Flutter app
/// uses. It brings its own material app and a transparent background, so the
/// page behind shows through.
class EmbeddedGame extends StatefulWidget {
  /// The game to play and show.
  final GameBloc bloc;

  /// Overrides the default theme.
  final ThemeData? theme;

  const EmbeddedGame({super.key, required this.bloc, this.theme});

  @override
  State<EmbeddedGame> createState() => _EmbeddedGameState();
}

class _EmbeddedGameState extends State<EmbeddedGame> {
  @override
  void initState() {
    super.initState();
    // Flags are set with a secondary click, which should not open the
    // browser's menu.
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
  }

  @override
  void dispose() {
    if (kIsWeb) BrowserContextMenu.enableContextMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData? theme = widget.theme;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: Pref.defaultBackgroundColour.color,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Another Mine",
      theme: theme ?? ThemeData(colorScheme: scheme, useMaterial3: true),
      darkTheme: theme == null
          ? ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Pref.defaultBackgroundColour.color,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            )
          : null,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocProvider<GameBloc>.value(
          value: widget.bloc,
          child: const GameBody(),
        ),
      ),
    );
  }
}
