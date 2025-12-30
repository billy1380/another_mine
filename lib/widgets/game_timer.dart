import 'dart:async';

import 'package:another_mine/bloc/game/game_bloc.dart';
import 'package:another_mine/widgets/digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GameTimer extends StatefulWidget {
  const GameTimer({
    super.key,
  });

  @override
  State<GameTimer> createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> {
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = Stream.periodic(const Duration(seconds: 1)).listen((event) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Digits(
      name: "Time",
      value: BlocProvider.of<GameBloc>(context).state.seconds,
      digits: 3,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
