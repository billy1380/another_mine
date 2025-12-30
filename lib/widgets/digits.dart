import 'dart:math';

import 'package:flutter/material.dart';

class Digits extends StatelessWidget {
  final String name;
  final int value;
  final int digits;

  const Digits({
    super.key,
    required this.name,
    required this.value,
    this.digits = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      child: Container(
        height: 48,
        width: ((digits * 25) + 16).toDouble(),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface,
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: Stack(
          children: [
            ..._digits(),
            Container(
              width: (digits * 45).toDouble(),
              height: 20,
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                  color: Color(0x60FFFFFF)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _digits() {
    List<Widget> widgets = <Widget>[];

    for (int i = 0; i < digits; i++) {
      widgets.add(Positioned(
        left: (25 * i).toDouble(),
        child: Image.asset(
          _image(_digit(value, digits - i)),
          height: 50,
        ),
      ));
    }

    return widgets;
  }

  String _image(int digit) {
    return "images/counter${digit >= 0 && digit < 10 ? digit : 0}.png";
  }

  int _digit(int number, int position) {
    return (number % pow(10, position).toInt()) ~/ pow(10, position - 1);
  }
}
