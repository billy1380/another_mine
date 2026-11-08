import "package:willshex_embedding/willshex_embedding.dart";

/// Where Another Mine asks its questions: in the host's dialog if it has one,
/// otherwise in its own.
///
/// Every dialog is a [DialogRequest] asked of a [PageSession]. The host that
/// embeds the game draws it in the host's style. Without a host that draws
/// dialogs (the game on its own, or in a host that does not), the game is its
/// own host: [local] is the controller its own client draws the requests of.
abstract class AnotherMineDialogs {
  AnotherMineDialogs._();

  /// The controller of the game's own dialogs. The client mounts a dialog host
  /// on it, which is what makes [PageSession.canShowDialog] true there.
  static final EmbeddingController local = EmbeddingController();

  static final PageSession _localSession = local.createPageSession(
    namespace: "another_mine_dialogs",
  );

  /// The session of the host that embeds the game, set while the game is
  /// shown in one.
  static PageSession? hostSession;

  /// Whether the game's own client draws dialogs, as there is no host that
  /// does. The client sets it while a dialog host is mounted.
  static bool get hasLocalHost => local.supportsDialogs;

  /// Asks [request]: the host draws it if it can, else the game does.
  ///
  /// Answers `null` if it was dismissed, or if nothing is there to draw it.
  static Future<DialogResult?> ask(DialogRequest request) {
    final PageSession? host = hostSession;

    if (host != null && !host.isDisposed && host.canShowDialog) {
      return host.showDialog(request);
    }

    return _localSession.showDialog(request);
  }
}
