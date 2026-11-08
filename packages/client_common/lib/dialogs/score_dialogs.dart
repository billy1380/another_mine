import "package:another_mine_common/dialogs/another_mine_dialogs.dart";
import "package:another_mine_common/scores/local_score.dart";
import "package:another_mine_common/scores/score_keeper.dart";
import "package:another_mine_common/strings.dart";
import "package:mine_images/mine_images.dart";
import "package:willshex_embedding/willshex_embedding.dart";

/// The dialogs about scores, asked through [AnotherMineDialogs] so that every
/// client, and every host, draws them in its own style.
abstract class ScoreDialogs {
  ScoreDialogs._();

  static const String nameField = "name";

  /// The picture of a place: the gold, silver or bronze medal for the first
  /// three, and the face that is not sure for the rest, as the Mac game did.
  static DialogImage imageFor(int place) {
    final MineImage image = switch (place) {
      1 => MineImage.medal1,
      2 => MineImage.medal2,
      3 => MineImage.medal3,
      _ => MineImage.dunno,
    };

    return DialogImage(
      asset: image.asset,
      package: MineImage.package,
      label: place >= 1 && place <= 3 ? "Place $place" : null,
    );
  }

  /// The question after a win: whose score is it? Answers the name to keep it
  /// under, or `null` if the player skipped.
  static Future<String?> askName(
    WonGame game,
    int place, {
    String initialName = "",
  }) async {
    final String board = game.category.label;
    final DialogResult? result = await AnotherMineDialogs.ask(
      DialogRequest.prompt(
        title: Strings.wonTitle,
        message:
            "${Strings.timeOnBoard(game.seconds, board)}\n"
            "${place == 1 ? Strings.bestTime : Strings.placeIn(place, board)}",
        field: DialogField(
          id: nameField,
          label: Strings.nameLabel,
          initialValue: initialName,
          maxLength: 30,
          isRequired: true,
        ),
        saveLabel: Strings.save,
        skipLabel: Strings.skip,
        image: imageFor(place),
      ),
    );

    final String name = result?.values[nameField] ?? "";

    return result?.actionId == "save" && name.isNotEmpty ? name : null;
  }

  /// Whether the player wants [score] deleted.
  static Future<bool> confirmDeleteScore(LocalScore score) async =>
      (await AnotherMineDialogs.ask(
        DialogRequest.confirm(
          title: Strings.deleteScoreTitle,
          message: Strings.deleteScoreQuestion(
            score.name,
            score.seconds,
            score.board,
          ),
          confirmLabel: Strings.delete,
          destructive: true,
        ),
      ))?.actionId ==
      "confirm";

  /// Whether the player wants every score of [category] deleted.
  static Future<bool> confirmDeleteAll(String category) async =>
      (await AnotherMineDialogs.ask(
        DialogRequest.confirm(
          title: Strings.deleteAllTitle,
          message: Strings.deleteAllQuestion(category),
          confirmLabel: Strings.delete,
          destructive: true,
        ),
      ))?.actionId ==
      "confirm";

  /// Tells the player that online scores are not available yet.
  static Future<void> onlineComingSoon() => AnotherMineDialogs.ask(
    DialogRequest(
      title: Strings.onlineComingSoonTitle,
      message: Strings.onlineComingSoonMessage,
      actions: const [DialogAction.cancel(label: Strings.ok)],
    ),
  );
}
