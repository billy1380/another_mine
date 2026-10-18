import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/game_state_type.dart";
import "package:another_mine/strings.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// Overflow menu with the auto solver, probabilities and focus mode toggles.
class GameToolsMenu extends StatelessWidget {
  const GameToolsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        final bool gameWon = state.status == GameStateType.won;
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz),
          tooltip: Strings.gameToolsTooltip,
          onSelected: (value) {
            final bloc = context.read<GameBloc>();
            switch (value) {
              case "solver":
                bloc.add(const ToggleAutoSolver());
                break;
              case "probability":
                bloc.add(const ToggleProbabilities());
                break;
              case "focus":
                bloc.add(const ToggleFocusMode());
                break;
            }
          },
          itemBuilder: (context) => [
            _buildPopupItem(
                "solver",
                state.autoSolverEnabled
                    ? Icons.smart_toy
                    : Icons.smart_toy_outlined,
                Strings.autoSolver,
                gameWon),
            _buildPopupItem(
                "probability",
                state.showProbability ? Icons.percent : Icons.percent_outlined,
                Strings.probabilities,
                gameWon),
            _buildPopupItem(
                "focus",
                state.isFocusMode
                    ? Icons.center_focus_strong
                    : Icons.center_focus_strong_outlined,
                Strings.focusMode,
                gameWon),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      String value, IconData icon, String label, bool isDisabled) {
    return PopupMenuItem(
      value: value,
      enabled: !isDisabled,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isDisabled ? Colors.grey : Colors.black),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: isDisabled ? Colors.grey : Colors.black)),
        ],
      ),
    );
  }
}
