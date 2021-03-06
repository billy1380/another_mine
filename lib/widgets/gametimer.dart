import 'dart:async';

import 'package:another_mine/model/game.dart';
import 'package:another_mine/widgets/digits.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameTimer extends StatefulWidget {
  const GameTimer({
    Key key,
  }) : super(key: key);

  @override
  _GameTimerState createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> {
  StreamSubscription _subscription;

  @override
  void initState() {
    _subscription = Stream.periodic(Duration(seconds: 1)).listen((event) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Digits(
      name: "Time",
      value: Provider.of<Game>(context).seconds,
      digits: 3,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
