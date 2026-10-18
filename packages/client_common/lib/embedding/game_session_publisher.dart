import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_common/embedding/another_mine_section.dart";
import "package:another_mine_common/model/game_difficulty.dart";
import "package:another_mine_common/model/game_state_type.dart";
import "package:another_mine_common/strings.dart";
import "package:willshex/willshex.dart";
import "package:willshex_embedding/willshex_embedding.dart";

/// Gives a host the title and actions of the current game, so that it can show
/// them in its own header. Shared by the Flutter and Jaspr clients.
class GameSessionPublisher {
  final GameBloc bloc;
  final PageSession session;

  // what the published title and actions were last built from
  Object? _publishedFor;

  GameSessionPublisher({required this.bloc, required this.session});

  /// Forget what was published, so the next [publish] sends it again.
  void invalidate() => _publishedFor = null;

  /// Publishes for [section], doing nothing if nothing the header shows has
  /// changed since last time.
  void publish(AnotherMineSection section) {
    if (section != AnotherMineSection.game) {
      if (_publishedFor != section) {
        _publishedFor = section;
        session.clearTitle();
        session.setActions(const []);
      }
      return;
    }

    final GameState state = bloc.state;
    final GameDifficulty difficulty = state.difficulty;
    // No game yet
    if (difficulty == GameDifficulty.none) return;

    // The state changes with every move and tick, the header only with these.
    final Object signature = (
      difficulty,
      state.status,
      state.autoSolverEnabled,
      state.autoSolverPaused,
      state.showProbability,
      state.isFocusMode,
    );
    if (signature == _publishedFor) return;
    _publishedFor = signature;

    final bool finished = state.status == GameStateType.won;

    PageAction toggle(
      String id,
      String label,
      bool on,
      void Function() onTrigger,
      double order,
    ) => PageAction(
      id: id,
      label: label,
      variant: on ? ActionVariant.primary : ActionVariant.outline,
      isEnabled: !finished,
      order: order,
      onTrigger: onTrigger,
    );

    session.setTitle(
      "${StringUtils.upperCaseFirstLetter(difficulty.name)} - ${difficulty.description}",
      subtitle: "Another Mine",
    );
    session.setActions([
      toggle(
        "solver",
        Strings.autoSolver,
        state.autoSolverEnabled,
        () => bloc.add(const ToggleAutoSolver()),
        1,
      ),
      toggle(
        "probability",
        Strings.probabilities,
        state.showProbability,
        () => bloc.add(const ToggleProbabilities()),
        2,
      ),
      toggle(
        "focus",
        Strings.focusMode,
        state.isFocusMode,
        () => bloc.add(const ToggleFocusMode()),
        3,
      ),
      if (state.autoSolverEnabled)
        PageAction(
          id: "solver_pause",
          label: state.autoSolverPaused ? "Resume solver" : "Pause solver",
          order: 4,
          onTrigger: () => bloc.add(
            state.autoSolverPaused
                ? const ResumeAutoSolver()
                : const PauseAutoSolver(),
          ),
        ),
    ]);
  }
}
