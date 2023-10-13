import 'package:another_mine/pages/anotherminegamepage.dart';
import 'package:another_mine/services/pref.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Another Mine",
      home: FutureBuilder(
          future: Pref.service.init("another_mine_"),
          initialData: null,
          builder: (context, snapshot) {
            return snapshot.hasData && snapshot.data!
                ? const AnotherMineGamePage()
                : const Center(child: CircularProgressIndicator());
          }),
    );
  }
}
