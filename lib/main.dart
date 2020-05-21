import 'package:another_mine/pages/anotherminegamepage.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
        defaultBrightness: Brightness.light,
        data: (brightness) => ThemeData(
            primarySwatch: Colors.deepPurple,
            brightness: brightness,
            visualDensity: VisualDensity.adaptivePlatformDensity),
        themedWidgetBuilder: (context, theme) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Another Mine",
            theme: theme,
            home: FutureBuilder(
                future: PrefService.init(prefix: "another_mine_"),
                initialData: null,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  return snapshot.data == null
                      ? Center(child: CircularProgressIndicator())
                      : AnotherMineGamePage();
                }),
          );
        });
  }
}
