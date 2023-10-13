import 'package:another_mine/model/game.dart';
import 'package:another_mine/model/tilemodel.dart';
import 'package:another_mine/widgets/tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Minefield extends StatelessWidget {
  const Minefield({super.key});

  @override
  Widget build(BuildContext context) {
    Game game = Provider.of<Game>(context);
    return GridView.count(
      crossAxisCount: game.difficulty.width,
      children: _tiles(game),
    );
  }

  List<Widget> _tiles(Game game) {
    List<Widget> tiles = <Widget>[];

    for (TileModel tile in game.tiles) {
      tiles.add(Tile(UniqueKey(), tile));
    }

    return tiles;
  }
}
