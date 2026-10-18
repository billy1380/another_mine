import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/another_mine_flutter.dart"
    show EmbeddedGame;
import "package:another_mine_web/ui/bloc_provider.dart";
import "package:another_mine_web/ui/layout.dart";
import "package:another_mine_web/ui/parts/game_tools.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";
import "package:jaspr_flutter_embed/jaspr_flutter_embed.dart";
import "package:willshex/willshex.dart";

/// A game on its own page, with the app's sidebar and header.
class GameScreen extends StatefulComponent {
  final GameDifficulty difficulty;
  final bool useLayout;

  const GameScreen({
    super.key,
    required this.difficulty,
    this.useLayout = true,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateComponent(GameScreen oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.difficulty != component.difficulty) _start();
  }

  void _start() {
    final GameBloc bloc = BlocProvider.of<GameBloc>(context);
    if (bloc.state.difficulty != component.difficulty) {
      bloc.add(NewGame(difficulty: component.difficulty));
    }
  }

  @override
  Component build(BuildContext context) {
    if (!component.useLayout) return const GameView();

    final GameBloc bloc = BlocProvider.of<GameBloc>(context);

    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        final GameDifficulty difficulty = state.difficulty;
        final bool started = difficulty != GameDifficulty.none;

        return AppLayout(
          title: started
              ? "${StringUtils.upperCaseFirstLetter(difficulty.name)} - ${difficulty.description}"
              : Strings.startupPageTitle,
          actions: [if (started) GameTools(bloc: bloc, state: state)],
          onSidebarChanged: (open) =>
              bloc.add(open ? const PauseGame() : const ResumeGame()),
          child: const GameView(),
        );
      },
    );
  }
}

/// The playing area: the mine count, new game button and timer above the
/// minefield, which are the Flutter widgets the Flutter app uses, hosted in an
/// embed view.
///
/// Used by the stand alone game screen and by the embeddable view, so it works
/// without the sidebar or a router. Needs a [GameBloc] above it, which the
/// Flutter side plays and shows.
class GameView extends StatelessComponent {
  const GameView({super.key});

  @override
  Component build(BuildContext context) {
    final GameBloc bloc = BlocProvider.of<GameBloc>(context);

    return div(
      attributes: const {"style": "height: 100%; min-height: 0;"},
      // Flags are set with a secondary click, which should not open the
      // browser's menu.
      events: {"contextmenu": (e) => e.preventDefault()},
      [
        FlutterEmbedView(
          classes: "w-100 h-100",
          widget: EmbeddedGame(bloc: bloc),
        ),
      ],
    );
  }
}
