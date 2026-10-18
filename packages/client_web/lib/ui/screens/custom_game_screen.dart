import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_web/ui/layout.dart";
import "package:another_mine_web/ui/parts/rag_indicator.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";
import "package:web/web.dart" as web;

/// Choosing a custom board on its own page.
class CustomGameScreen extends StatelessComponent {
  final bool useLayout;
  final String basePath;
  final void Function(GameDifficulty difficulty) onStart;

  const CustomGameScreen({
    super.key,
    required this.onStart,
    this.useLayout = true,
    this.basePath = "",
  });

  @override
  Component build(BuildContext context) {
    final Component view = CustomGameView(onStart: onStart);
    if (!useLayout) return view;

    return AppLayout(title: "Custom game", basePath: basePath, child: view);
  }
}

/// Pick a board size and mine count. Saves the choice and calls [onStart].
class CustomGameView extends StatefulComponent {
  final void Function(GameDifficulty difficulty) onStart;

  const CustomGameView({super.key, required this.onStart});

  @override
  State<CustomGameView> createState() => _CustomGameViewState();
}

class _CustomGameViewState extends State<CustomGameView> {
  late int _width;
  late int _height;
  late int _mines;

  @override
  void initState() {
    super.initState();
    final GameDifficulty difficulty = Provider.pref.difficulty;
    _width = difficulty.width.clamp(CustomGame.minWidth, CustomGame.maxWidth);
    _height = difficulty.height.clamp(
      CustomGame.minHeight,
      CustomGame.maxHeight,
    );
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

    component.onStart(difficulty);
  }

  Component _slider({
    required String label,
    required int value,
    required int min,
    required int max,
    required void Function(int value) onChanged,
  }) {
    return div(classes: "mb-4", [
      label_(label, value),
      div(classes: "d-flex align-items-center gap-2", [
        span(classes: "text-secondary small", [Component.text("$min")]),
        input(
          type: InputType.range,
          classes: "form-range",
          value: "$value",
          attributes: {"min": "$min", "max": "$max", "step": "1"},
          events: {
            "input": (e) {
              final int? next = int.tryParse(
                (e.target as web.HTMLInputElement).value,
              );
              if (next != null) setState(() => onChanged(next));
            },
          },
        ),
        span(classes: "text-secondary small", [Component.text("$max")]),
      ]),
    ]);
  }

  Component label_(String label, int value) => div(
    classes: "form-label fw-semibold",
    [Component.text("$label: $value")],
  );

  @override
  Component build(BuildContext context) {
    final int maxMines = CustomGame.maxMinesFor(_width, _height);

    return div(
      attributes: const {
        "style": "max-width: 640px; margin: 0 auto; padding: 1.5rem 1rem 3rem;",
      },
      [
        div(classes: "d-flex align-items-center justify-content-between mb-4", [
          select(
            classes: "form-select w-auto",
            events: {
              "change": (e) {
                final String name = (e.target as web.HTMLSelectElement).value;
                final GameDifficulty? chosen = GameDifficulty.values
                    .where((d) => d.name == name)
                    .firstOrNull;
                if (chosen == null) return;
                setState(() {
                  _width = chosen.width;
                  _height = chosen.height;
                  _mines = CustomGame.clampMines(chosen.mines, _width, _height);
                });
              },
            },
            [
              option(
                value: customName,
                selected:
                    CustomGame.nameFor(_width, _height, _mines) == "Custom",
                [Component.text(CustomGame.nameFor(_width, _height, _mines))],
              ),
              for (final GameDifficulty d in GameDifficulty.values)
                option(
                  value: d.name,
                  selected: d.sameAs(_width, _height, _mines),
                  [
                    Component.text(
                      CustomGame.nameFor(d.width, d.height, d.mines),
                    ),
                  ],
                ),
            ],
          ),
          RagIndicator(width: _width, height: _height, mines: _mines),
        ]),
        _slider(
          label: "Width",
          value: _width,
          min: CustomGame.minWidth,
          max: CustomGame.maxWidth,
          onChanged: (v) {
            _width = v;
            _mines = CustomGame.clampMines(_mines, _width, _height);
          },
        ),
        _slider(
          label: "Height",
          value: _height,
          min: CustomGame.minHeight,
          max: CustomGame.maxHeight,
          onChanged: (v) {
            _height = v;
            _mines = CustomGame.clampMines(_mines, _width, _height);
          },
        ),
        _slider(
          label: "Mines",
          value: _mines,
          min: CustomGame.minMines,
          max: maxMines,
          onChanged: (v) => _mines = v,
        ),
        button(
          classes: "btn btn-primary w-100",
          attributes: const {"type": "button"},
          events: {"click": (e) => _start()},
          const [Component.text(Strings.start)],
        ),
      ],
    );
  }
}
