import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/extensions/colour_ex.dart";
import "package:another_mine_flutter/widgets/game_body.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// The mine count, new game button, timer and minefield, for a page that is
/// not Flutter (a Jaspr page through a Flutter embed view).
///
/// The page keeps the [bloc], so its own sidebar and header can follow the
/// game, and this draws the playing area with the same widgets the Flutter app
/// uses. It brings its own material app and a transparent background, so the
/// page behind shows through.
///
/// The browser's context menu is not handled here: `BrowserContextMenu` needs
/// the app's main view, which an embedded view is not. The page cancels the
/// menu on the element around the view instead.
class EmbeddedGame extends StatelessWidget {
  /// The game to play and show.
  final GameBloc bloc;

  /// Overrides the default theme.
  final ThemeData? theme;

  const EmbeddedGame({super.key, required this.bloc, this.theme});

  @override
  Widget build(BuildContext context) {
    final Color seed = Pref.defaultBackgroundColour.color;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Another Mine",
      theme:
          theme ??
          ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: seed),
            useMaterial3: true,
          ),
      darkTheme: theme == null
          ? ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            )
          : null,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocProvider<GameBloc>.value(
          value: bloc,
          child: const GameBody(),
        ),
      ),
    );
  }
}
