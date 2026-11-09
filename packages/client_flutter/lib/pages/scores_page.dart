import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/pages/parts/app_drawer.dart";
import "package:another_mine_flutter/widgets/scores_list.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class ScoresPage extends StatefulWidget {
  static const String routePath = "/scores";
  static GoRouterWidgetBuilder builder = (context, state) =>
      ScoresPage._(category: GameRoutes.tabFrom(state.uri.queryParameters));

  /// The tab to start on, from `?tab=`.
  final ScoreCategory category;

  const ScoresPage._({required this.category});

  @override
  State<ScoresPage> createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(elevation: 0),
      body: ScoresList(
        initialCategory: widget.category,
        onCategoryChanged: (category) =>
            context.replace(GameRoutes.scoresPath(category)),
      ),
    );
  }
}
