import "package:another_mine_common/dialogs/another_mine_dialogs.dart";
import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/presentation/custom_game.dart";
import "package:another_mine_common/services/provider.dart";
import "package:another_mine_common/strings.dart";
import "package:willshex_embedding/willshex_embedding.dart";

/// The custom game dialog: a board's size and mines to pick, written once as a
/// [DialogRequest] that every client, and every host, draws as a Material
/// dialog in its own way.
///
/// The form holds the width, height and mines, and answers every change a
/// person makes with the request to show next: the mines slider's top follows
/// the board size, a preset sets all three, and the traffic light follows the
/// density.
class CustomGameForm {
  static const String presetId = "preset";
  static const String widthId = "width";
  static const String heightId = "height";
  static const String minesId = "mines";
  static const String startId = "start";

  static const String _customValue = "custom";

  int width;
  int height;
  int mines;

  /// Starts on [initial], kept within what the form allows.
  CustomGameForm(GameDifficulty initial)
    : width = initial.width.clamp(CustomGame.minWidth, CustomGame.maxWidth),
      height = initial.height.clamp(CustomGame.minHeight, CustomGame.maxHeight),
      mines = CustomGame.clampMines(
        initial.mines,
        initial.width.clamp(CustomGame.minWidth, CustomGame.maxWidth),
        initial.height.clamp(CustomGame.minHeight, CustomGame.maxHeight),
      );

  GameDifficulty get difficulty =>
      GameDifficulty.custom(width: width, height: height, mines: mines);

  /// The value of the choice that matches the board: a preset's name, or
  /// custom.
  String get _presetValue {
    for (final GameDifficulty preset in GameDifficulty.values) {
      if (preset.sameAs(width, height, mines)) return preset.name;
    }

    return _customValue;
  }

  /// The dialog for the board as it is now.
  DialogRequest request() {
    final Rag rag = ragFor(width, height, mines);

    return DialogRequest(
      title: Strings.customGameTitle,
      controls: [
        DialogRow(
          id: "top",
          children: [
            DialogChoice(
              id: presetId,
              options: [
                if (_presetValue == _customValue)
                  const DialogOption(_customValue, "Custom"),
                for (final GameDifficulty preset in GameDifficulty.values)
                  DialogOption(
                    preset.name,
                    CustomGame.nameFor(
                      preset.width,
                      preset.height,
                      preset.mines,
                    ),
                  ),
              ],
              value: _presetValue,
            ),
            DialogIndicator(
              id: "rag",
              colours: const [0xFF4CAF50, 0xFFFF9800, 0xFFF44336],
              active: rag.index,
              label: switch (rag) {
                Rag.green => "Easy",
                Rag.amber => "Medium",
                Rag.red => "Hard",
              },
            ),
          ],
        ),
        DialogSlider(
          id: widthId,
          label: Strings.customWidth,
          min: CustomGame.minWidth.toDouble(),
          max: CustomGame.maxWidth.toDouble(),
          value: width.toDouble(),
        ),
        DialogSlider(
          id: heightId,
          label: Strings.customHeight,
          min: CustomGame.minHeight.toDouble(),
          max: CustomGame.maxHeight.toDouble(),
          value: height.toDouble(),
        ),
        DialogSlider(
          id: minesId,
          label: Strings.customMines,
          min: CustomGame.minMines.toDouble(),
          max: CustomGame.maxMinesFor(width, height).toDouble(),
          value: mines.toDouble(),
        ),
      ],
      actions: [
        DialogAction.cancel(label: Strings.cancel),
        DialogAction(
          id: startId,
          label: Strings.start,
          variant: ActionVariant.primary,
        ),
      ],
      onChanged: _changed,
    );
  }

  DialogRequest? _changed(DialogChange change) {
    switch (change.controlId) {
      case presetId:
        final GameDifficulty? preset = GameDifficulty.values
            .where((p) => p.name == change.value)
            .firstOrNull;

        if (preset == null) return null;

        width = preset.width;
        height = preset.height;
        mines = CustomGame.clampMines(preset.mines, width, height);
      case widthId:
        width = (change.value as double).round().clamp(
          CustomGame.minWidth,
          CustomGame.maxWidth,
        );
        mines = CustomGame.clampMines(mines, width, height);
      case heightId:
        height = (change.value as double).round().clamp(
          CustomGame.minHeight,
          CustomGame.maxHeight,
        );
        mines = CustomGame.clampMines(mines, width, height);
      case minesId:
        mines = CustomGame.clampMines(
          (change.value as double).round(),
          width,
          height,
        );
      default:
        return null;
    }

    return request();
  }

  /// Asks for a custom board, starting on the one last played, and keeps the
  /// choice for next time. Answers `null` if it was cancelled.
  static Future<GameDifficulty?> ask() async {
    final CustomGameForm form = CustomGameForm(Provider.pref.difficulty);
    final DialogResult? result = await AnotherMineDialogs.ask(form.request());

    if (result?.actionId != startId) return null;

    final GameDifficulty difficulty = form.difficulty;

    await Provider.pref.setInt("width", difficulty.width);
    await Provider.pref.setInt("height", difficulty.height);
    await Provider.pref.setInt("mines", difficulty.mines);

    return difficulty;
  }
}
