import "package:another_mine_common/another_mine_common.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";

/// Buttons for the auto solver, probabilities and focus mode, and for pausing
/// the solver while it plays.
class GameTools extends StatelessComponent {
  final GameBloc bloc;
  final GameState state;

  const GameTools({super.key, required this.bloc, required this.state});

  Component _toggle(
    String label,
    String icon,
    bool on,
    void Function() onTrigger,
  ) {
    return button(
      classes: "btn btn-sm ${on ? "btn-primary" : "btn-outline-secondary"}",
      attributes: {
        "type": "button",
        "title": label,
        "aria-pressed": on ? "true" : "false",
        if (state.status == GameStateType.won) "disabled": "",
      },
      events: {"click": (e) => onTrigger()},
      [
        i(classes: "bi $icon me-1", const []),
        span(classes: "d-none d-sm-inline", [Component.text(label)]),
      ],
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      if (state.autoSolverEnabled)
        button(
          classes: "btn btn-sm btn-outline-primary",
          attributes: {
            "type": "button",
            "title": state.autoSolverPaused ? "Resume solver" : "Pause solver",
          },
          events: {
            "click": (e) => bloc.add(
              state.autoSolverPaused
                  ? const ResumeAutoSolver()
                  : const PauseAutoSolver(),
            ),
          },
          [
            i(
              classes:
                  "bi ${state.autoSolverPaused ? "bi-play-fill" : "bi-pause-fill"}",
              const [],
            ),
          ],
        ),
      _toggle(
        Strings.autoSolver,
        "bi-robot",
        state.autoSolverEnabled,
        () => bloc.add(const ToggleAutoSolver()),
      ),
      _toggle(
        Strings.probabilities,
        "bi-percent",
        state.showProbability,
        () => bloc.add(const ToggleProbabilities()),
      ),
      _toggle(
        Strings.focusMode,
        "bi-bullseye",
        state.isFocusMode,
        () => bloc.add(const ToggleFocusMode()),
      ),
    ]);
  }
}
