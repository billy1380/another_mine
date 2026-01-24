import "package:another_mine/bloc/startup/startup_bloc.dart";
import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/pages/game_page.dart";
import "package:another_mine/services/provider.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";

class StartupPage extends StatefulWidget {
  static const String routerPath = "/startup";

  static GoRouterWidgetBuilder builder = (context, state) => StartupPage._(
        from: state.uri.queryParameters["from"],
      );

  final String? from;

  const StartupPage._({
    this.from,
  });

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();
    // Trigger initialization if not already done
    context.read<StartupBloc>().add(const InitializeApp());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StartupBloc, StartupState>(
      listener: (context, state) {
        if (state.status == StartupStatus.complete) {
          GameDifficulty difficulty = Provider.pref.difficulty;
          GoRouter.of(context)
              .go(widget.from ?? GamePage.buildRoute(difficulty));
        }
      },
      child: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
