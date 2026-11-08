import "package:another_mine_common/dialogs/another_mine_dialogs.dart";
import "package:another_mine_common/scores/local_score.dart";
import "package:another_mine_common/scores/score_category.dart";
import "package:another_mine_common/scores/score_keeper.dart";
import "package:another_mine_common/scores/score_row.dart";
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
  /// under, or `null` if the player skipped. With [askForName] false the player
  /// is known (the online player), so it only congratulates and answers
  /// [initialName].
  static Future<String?> askName(
    WonGame game,
    int place, {
    String initialName = "",
    bool askForName = true,
  }) async {
    final String board = game.category.label;

    if (!askForName) {
      await AnotherMineDialogs.ask(
        DialogRequest(
          title: Strings.wonTitle,
          message:
              "${Strings.timeOnBoard(game.seconds, board)}\n"
              "${place == 1 ? Strings.bestTime : Strings.placeIn(place, board)}",
          image: imageFor(place),
          actions: const [
            DialogAction(
              id: "ok",
              label: Strings.ok,
              variant: ActionVariant.primary,
              isCancel: true,
            ),
          ],
        ),
      );

      return initialName.isEmpty ? null : initialName;
    }

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

  static const String retryId = "retry";
  static const String localId = "local";

  /// The lines of the table for [category]. When the online scores cannot be
  /// read, asks whether to try again, give up or switch to local scores, and
  /// answers `null` for the last two (after a switch, [ScoreKeeper.showsOnline]
  /// is false, so the caller shows the local tabs).
  static Future<List<ScoreRow>?> loadRows(
    ScoreKeeper keeper,
    ScoreCategory category,
  ) async {
    while (true) {
      try {
        return await keeper.rows(category);
      } catch (_) {
        if (!keeper.showsOnline) rethrow;

        final DialogResult? result = await AnotherMineDialogs.ask(
          const DialogRequest(
            title: Strings.scoresFailedTitle,
            message: Strings.scoresFailedMessage,
            actions: [
              DialogAction.cancel(label: Strings.cancel),
              DialogAction(id: localId, label: Strings.switchToLocal),
              DialogAction(
                id: retryId,
                label: Strings.retry,
                variant: ActionVariant.primary,
              ),
            ],
          ),
        );

        if (result?.actionId == retryId) continue;
        if (result?.actionId == localId) await keeper.switchToLocal();

        return null;
      }
    }
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

  /// Tells the player that the recording of a game could not be replayed.
  static Future<void> replayUnreadable() async {
    await AnotherMineDialogs.ask(
      const DialogRequest(
        title: Strings.replayUnreadableTitle,
        message: Strings.replayUnreadableMessage,
        actions: [DialogAction.cancel(label: Strings.cancel)],
      ),
    );
  }
}
