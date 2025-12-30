import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/routes.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameBloc(),
      child: MaterialApp.router(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: defaultBackgroundColour,
          ),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        title: "Another Mine",
        routerConfig: router,
      ),
    );
  }
}
