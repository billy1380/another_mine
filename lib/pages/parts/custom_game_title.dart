import "package:another_mine/model/game_difficulty.dart";
import "package:another_mine/pages/parts/rag_indicator.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:willshex/willshex.dart";

class CustomGameTitle extends StatelessWidget {
  final int width;
  final int height;
  final int mines;
  final ValueChanged<GameDifficulty>? onDifficultySelected;

  const CustomGameTitle({
    super.key,
    required this.width,
    required this.height,
    required this.mines,
    this.onDifficultySelected,
  });

  String get _name {
    GameDifficulty? difficulty = GameDifficulty.values
        .firstWhereOrNull((e) => e.sameAs(width, height, mines));

    return StringUtils.upperCaseFirstLetter(difficulty?.name) ?? "Custom";
  }

  @override
  Widget build(BuildContext context) {
    final currentFactor = mines / (width * height);
    final bFactor =
        GameDifficulty.beginner.mines / GameDifficulty.beginner.area;
    final iFactor =
        GameDifficulty.intermediate.mines / GameDifficulty.intermediate.area;
    final eFactor = GameDifficulty.expert.mines / GameDifficulty.expert.area;

    final biMid = bFactor + ((iFactor - bFactor) * 0.5);
    final ieMid = iFactor + ((eFactor - iFactor) * 0.5);

    return Row(children: [
      if (onDifficultySelected != null)
        PopupMenuButton<GameDifficulty>(
          onSelected: (value) => onDifficultySelected!(value),
          itemBuilder: (context) => GameDifficulty.values
              .map((e) => PopupMenuItem(
                    value: e,
                    child: Text(StringUtils.upperCaseFirstLetter(e.name) ??
                        e.name.toUpperCase()),
                  ))
              .toList(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_name),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        )
      else
        Text(_name),
      const Spacer(),
      RagIndicator(
        value: currentFactor,
        thresholdToAmber: biMid,
        thresholdToRed: ieMid,
      ),
    ]);
  }
}
