import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_web/ui/screens/game_screen.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";

class CustomGameScreen extends StatelessComponent {
  final bool useLayout;
  final String basePath;
  final void Function(GameDifficulty difficulty) onStart;
  final void Function() onCancel;

  const CustomGameScreen({
    super.key,
    required this.onStart,
    required this.onCancel,
    this.useLayout = true,
    this.basePath = "",
  });

  @override
  Component build(BuildContext context) {
    return GameScreen(
      difficulty: Provider.pref.difficulty,
      useLayout: useLayout,
      basePath: basePath,
      overlay: CustomGameLauncher(onStart: onStart, onCancel: onCancel),
    );
  }
}

/// Asks for a custom board as soon as it is shown, in the dialog that every
/// client and host draws as a Material dialog, then says what was chosen.
///
/// It draws nothing itself.
class CustomGameLauncher extends StatefulComponent {
  final void Function(GameDifficulty difficulty) onStart;
  final void Function() onCancel;

  const CustomGameLauncher({
    super.key,
    required this.onStart,
    required this.onCancel,
  });

  @override
  State<CustomGameLauncher> createState() => _CustomGameLauncherState();
}

class _CustomGameLauncherState extends State<CustomGameLauncher> {
  @override
  void initState() {
    super.initState();
    _ask();
  }

  Future<void> _ask() async {
    final GameDifficulty? difficulty = await CustomGameForm.ask();

    if (!mounted) return;

    if (difficulty == null) {
      component.onCancel();
    } else {
      component.onStart(difficulty);
    }
  }

  @override
  Component build(BuildContext context) =>
      const div(attributes: {"hidden": ""}, []);
}
