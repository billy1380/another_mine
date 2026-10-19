import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_flutter/pages/parts/custom_game_body.dart";
import "package:another_mine_flutter/pages/parts/custom_game_title.dart";
import "package:flutter/material.dart";

Future<GameDifficulty?> showCustomGameDialog(BuildContext context) =>
    showDialog<GameDifficulty>(
      context: context,
      builder: (context) => const CustomGameDialog(),
    );

class CustomGameDialog extends StatefulWidget {
  const CustomGameDialog({super.key});

  @override
  State<CustomGameDialog> createState() => _CustomGameDialogState();
}

class _CustomGameDialogState extends State<CustomGameDialog> {
  late int _width;
  late int _height;
  late int _mines;

  int get _maxMines => CustomGame.maxMinesFor(_width, _height);

  @override
  void initState() {
    super.initState();
    final GameDifficulty difficulty = Provider.pref.difficulty;
    _width = difficulty.width;
    _height = difficulty.height;
    _mines = CustomGame.clampMines(difficulty.mines, _width, _height);
  }

  Future<void> _start() async {
    final GameDifficulty difficulty = GameDifficulty.custom(
      width: _width,
      height: _height,
      mines: _mines,
    );

    await Provider.pref.setInt("width", difficulty.width);
    await Provider.pref.setInt("height", difficulty.height);
    await Provider.pref.setInt("mines", difficulty.mines);

    if (mounted) Navigator.of(context).pop(difficulty);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Custom game",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              CustomGameTitle(
                width: _width,
                height: _height,
                mines: _mines,
                onDifficultySelected: (value) => setState(() {
                  _width = value.width;
                  _height = value.height;
                  _mines = CustomGame.clampMines(value.mines, _width, _height);
                }),
              ),
              Flexible(
                child: CustomGameBody(
                  width: _width,
                  height: _height,
                  mines: _mines,
                  maxMines: _maxMines,
                  onWidthChanged: (value) => setState(() {
                    _width = value;
                    _mines = CustomGame.clampMines(_mines, _width, _height);
                  }),
                  onHeightChanged: (value) => setState(() {
                    _height = value;
                    _mines = CustomGame.clampMines(_mines, _width, _height);
                  }),
                  onMinesChanged: (value) => setState(() => _mines = value),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(Strings.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _start,
                    child: const Text(Strings.start),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
