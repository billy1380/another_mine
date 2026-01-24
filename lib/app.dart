import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/bloc/startup/startup_bloc.dart";
import "package:another_mine/routes.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:main_thread_processor/main_thread_processor.dart";

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final StartupBloc _startupBloc;
  late final RouterConfig<Object> _router;

  @override
  void initState() {
    super.initState();
    _startupBloc = StartupBloc();
    _router = createRouter(_startupBloc);
  }

  @override
  void dispose() {
    _startupBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _startupBloc),
        BlocProvider(
          create: (context) => GameBloc(
            processor: Processor.shared,
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: defaultBackgroundColour,
          ),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        title: "Another Mine",
        routerConfig: _router,
      ),
    );
  }
}