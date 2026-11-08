import "package:another_mine_common/another_mine_common.dart";
import "package:another_mine_web/ui/bloc_provider.dart";
import "package:another_mine_web/ui/layout.dart";
import "package:another_mine_web/ui/parts/small_picture.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";
import "package:web/web.dart" as web;
import "package:willshex_embedding/willshex_embedding.dart";

/// Settings on their own page.
class SettingsScreen extends StatelessComponent {
  final bool useLayout;
  final String basePath;

  const SettingsScreen({super.key, this.useLayout = true, this.basePath = ""});

  @override
  Component build(BuildContext context) {
    if (!useLayout) return const SettingsView();

    return AppLayout(
      title: Strings.settingsTitle,
      basePath: basePath,
      child: const SettingsView(),
    );
  }
}

/// The game's settings. Changes are saved straight away; those that change how
/// the board looks are passed on to a running game.
class SettingsView extends StatefulComponent {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late bool _animate;
  late int _scoresRetained;
  late bool _remoteScoresEnabled;
  late bool _customBgEnabled;
  late int _customBgColor;
  late AutoSolverType _autoSolverType;

  @override
  void initState() {
    super.initState();
    final Pref pref = Provider.pref;
    _animate = pref.animate;
    _scoresRetained = pref.scoresRetained;
    _remoteScoresEnabled = pref.remoteScoresEnabled;
    _customBgEnabled = pref.customBgEnabled;
    _customBgColor = pref.customBgColor;
    _autoSolverType = pref.autoSolverType;
  }

  void _refreshGame() {
    BlocProvider.maybeOf<GameBloc>(context)?.add(const RefreshSettings());
  }

  /// `name · [logo] service · [flag] country`; hovering a picture says what it is.
  Component _onlinePlayerSummary() {
    final OnlinePlayer player = onlineScores.player;
    final DialogImage? flag = flagOf(player.country);

    return div(
      classes: "d-flex align-items-center gap-2 small text-secondary",
      [
        Component.text("${player.name} ·"),
        smallPicture(serviceImage(player.service), height: 20),
        Component.text("${serviceName(player.service)} ·"),
        if (flag != null) smallPicture(flag),
        Component.text(countryName(player.country)),
      ],
    );
  }

  Component _heading(String text) => h3(
    classes: "h6 text-secondary text-uppercase mt-4 mb-2",
    [Component.text(text)],
  );

  Component _switch({
    required String id,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool value) onChanged,
    bool enabled = true,
  }) {
    return div(classes: "form-check form-switch my-3", [
      input(
        type: InputType.checkbox,
        classes: "form-check-input",
        id: id,
        checked: value,
        attributes: {if (!enabled) "disabled": ""},
        events: {
          "change": (e) =>
              onChanged((e.target as web.HTMLInputElement).checked),
        },
      ),
      label(
        classes: "form-check-label ms-2",
        attributes: {"for": id},
        [
          div(classes: "fw-medium", [Component.text(title)]),
          div(classes: "small text-secondary", [Component.text(subtitle)]),
        ],
      ),
    ]);
  }

  Component _colourHex(int argb) => Component.text(Colour(argb).hex);

  @override
  Component build(BuildContext context) {
    final Pref pref = Provider.pref;

    return div(
      classes: "p-4 p-md-5 overflow-auto",
      attributes: const {"style": "max-width: 640px; margin: 0 auto;"},
      [
        _heading(Strings.gameSection),
        _switch(
          id: "animate",
          title: Strings.animationsTitle,
          subtitle: Strings.animationsSubtitle,
          value: _animate,
          onChanged: (v) {
            setState(() => _animate = v);
            pref.setBool(Pref.keyAnimate, v);
          },
        ),
        div(classes: "my-3", [
          label(
            classes: "form-label fw-medium",
            attributes: const {"for": "solverType"},
            [const Component.text(Strings.autoSolverStrategyTitle)],
          ),
          select(
            classes: "form-select",
            id: "solverType",
            events: {
              "change": (e) {
                final String name = (e.target as web.HTMLSelectElement).value;
                final AutoSolverType type = AutoSolverType.values.firstWhere(
                  (t) => t.name == name,
                  orElse: () => _autoSolverType,
                );
                setState(() => _autoSolverType = type);
                pref.setString(Pref.keyAutoSolverType, type.name);
              },
            },
            [
              for (final AutoSolverType type in AutoSolverType.values)
                option(value: type.name, selected: type == _autoSolverType, [
                  Component.text(type.title),
                ]),
            ],
          ),
          div(classes: "form-text", [
            Component.text(_autoSolverType.description),
          ]),
        ]),
        _heading(Strings.highScoresSection),
        div(classes: "my-3", [
          label(
            classes: "form-label fw-medium",
            attributes: const {"for": "scoresRetained"},
            [Component.text(Strings.localScoresRetainedTitle)],
          ),
          input(
            type: InputType.range,
            classes: "form-range",
            id: "scoresRetained",
            value: "$_scoresRetained",
            attributes: const {"min": "10", "max": "99", "step": "1"},
            events: {
              "input": (e) {
                final int? v = int.tryParse(
                  (e.target as web.HTMLInputElement).value,
                );
                if (v == null) return;
                setState(() => _scoresRetained = v);
                pref.setInt(Pref.keyScoresRetained, v);
              },
            },
          ),
          div(classes: "form-text", [
            Component.text(
              Strings.keepUpToScores.replaceFirst("%s", "$_scoresRetained"),
            ),
          ]),
        ]),
        _switch(
          id: "remoteScores",
          title: Strings.onlineHighScoresTitle,
          subtitle: Strings.onlineHighScoresSubtitle,
          value: _remoteScoresEnabled,
          onChanged: (v) async {
            final bool changed = v
                ? await onlineScores.turnOn()
                : await onlineScores.turnOff();

            if (changed) {
              setState(() => _remoteScoresEnabled = v);
            } else {
              (web.document.getElementById(
                "remoteScores",
              ) as web.HTMLInputElement).checked = _remoteScoresEnabled;
            }
          },
        ),
        if (_remoteScoresEnabled)
          button(
            classes:
                "btn btn-link text-start text-decoration-none p-0 my-3 d-block",
            attributes: const {"type": "button"},
            events: {
              "click": (e) async {
                await onlineScores.edit();
                setState(() {});
              },
            },
            [
              div(classes: "fw-medium", [
                Component.text(Strings.onlinePlayerTitle),
              ]),
              _onlinePlayerSummary(),
            ],
          ),
        _heading(Strings.appearanceSection),
        _switch(
          id: "customBg",
          title: Strings.customBgColorEnabledTitle,
          subtitle: Strings.customBgColorEnabledSubtitle,
          value: _customBgEnabled,
          onChanged: (v) async {
            setState(() => _customBgEnabled = v);
            await pref.setBool(Pref.keyCustomBgEnabled, v);
            _refreshGame();
          },
        ),
        if (_customBgEnabled)
          div(
            classes: "d-flex align-items-center justify-content-between my-3",
            [
              label(
                classes: "form-label fw-medium mb-0",
                attributes: const {"for": "bgColour"},
                [Component.text(Strings.backgroundColorTitle)],
              ),
              div(classes: "d-flex align-items-center gap-2", [
                span(classes: "text-secondary small", [
                  _colourHex(_customBgColor),
                ]),
                input(
                  type: InputType.color,
                  attributes: const {
                    "style":
                        "width: 40px; height: 40px; padding: 0;"
                        " border: 1px solid var(--bs-border-color);"
                        " border-radius: 4px; background: none;",
                  },
                  id: "bgColour",
                  value: Colour(_customBgColor).hex,
                  events: {
                    "change": (e) async {
                      final String hex = (e.target as web.HTMLInputElement)
                          .value
                          .replaceFirst("#", "");
                      final int? rgb = int.tryParse(hex, radix: 16);
                      if (rgb == null) return;
                      final int argb = 0xFF000000 | rgb;
                      setState(() => _customBgColor = argb);
                      await pref.setInt(Pref.keyCustomBgColor, argb);
                      _refreshGame();
                    },
                  },
                ),
              ]),
            ],
          ),
      ],
    );
  }
}
