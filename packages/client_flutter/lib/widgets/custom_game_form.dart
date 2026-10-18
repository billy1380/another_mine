import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/services/provider.dart";
import "package:another_mine_common/strings.dart";
import "package:another_mine_flutter/pages/parts/custom_game_body.dart";
import "package:another_mine_flutter/pages/parts/custom_game_title.dart";
import "package:flutter/material.dart";

/// Pick a custom board size and mine count, on a page rather than in a dialog.
class CustomGameForm extends StatefulWidget {
  /// Called after the chosen difficulty has been saved.
  final ValueChanged<GameDifficulty> onStart;

  const CustomGameForm({super.key, required this.onStart});

  @override
  State<CustomGameForm> createState() => _CustomGameFormState();
}

class _CustomGameFormState extends State<CustomGameForm> {
  late int _width;
  late int _height;
  late int _mines;

  int get _maxMines => ((_width * _height) - 9).clamp(1, 1 << 20);

  @override
  void initState() {
    super.initState();
    final GameDifficulty difficulty = Provider.pref.difficulty;
    _width = difficulty.width;
    _height = difficulty.height;
    _mines = difficulty.mines;
  }

  void _clampMines() {
    if (_mines > _maxMines) _mines = _maxMines;
    if (_mines < 1) _mines = 1;
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

    if (mounted) widget.onStart(difficulty);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomGameTitle(
                width: _width,
                height: _height,
                mines: _mines,
                onDifficultySelected: (value) => setState(() {
                  _width = value.width;
                  _height = value.height;
                  _mines = value.mines;
                  _clampMines();
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
                    _clampMines();
                  }),
                  onHeightChanged: (value) => setState(() {
                    _height = value;
                    _clampMines();
                  }),
                  onMinesChanged: (value) => setState(() => _mines = value),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _start, child: const Text(Strings.start)),
            ],
          ),
        ),
      ),
    );
  }
}
