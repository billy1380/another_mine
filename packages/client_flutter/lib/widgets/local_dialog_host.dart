import "package:another_mine_common/another_mine_common.dart";
import "package:flutter/material.dart";
import "package:willshex_embedding_flutter/willshex_embedding_flutter.dart";

/// Shows the game's own dialogs, for when no host draws them: Material dialogs,
/// drawn by `willshex_embedding_flutter`, the same as a host of
/// `willshex_embedding` draws them.
///
/// Mount it once, next to the navigator whose context dialogs are shown in
/// ([navigatorKey]). While it is mounted, [AnotherMineDialogs.local] tells the
/// game that dialogs are drawn here.
class LocalDialogHost extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const LocalDialogHost({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => EmbeddingDialogHost(
    controller: AnotherMineDialogs.local,
    navigatorKey: navigatorKey,
    child: child,
  );
}
